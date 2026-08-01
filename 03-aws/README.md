# Module 3 — Premiers pas avec AWS

> Ce module suppose que tu as fait les [Module 1](../01-bases-locales/README.md) et [Module 2](../02-aller-plus-loin-en-local/README.md) — les notions de base (provider, resource, cycle de vie, state, variables, outputs, `for_each`) sont supposées acquises et ne sont pas réexpliquées ici en détail.

## Ce qui change par rapport aux modules précédents

Jusqu'ici, on manipulait uniquement le disque dur local (provider `local`) : aucun risque, aucun coût, aucune authentification. Ici, on pilote un **vrai compte cloud AWS** : les ressources créées existent réellement chez AWS, peuvent avoir un coût, et nécessitent de **prouver son identité** avant que quoi que ce soit ne fonctionne.

## Étape 1 — Le provider AWS et l'authentification

```hcl
# provider.tf
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

Deux providers sont déclarés cette fois : `aws` (pour parler à AWS) et `tls` (pour générer des clés cryptographiques — voir plus bas). On peut combiner autant de providers que nécessaire dans un même projet.

**Le point le plus important de ce fichier : il n'y a AUCUNE clé d'accès dedans.** Le bloc `provider "aws"` précise seulement la **région** (`eu-west-3` = Paris). Terraform va chercher les identifiants d'authentification **automatiquement**, dans cet ordre de priorité :
1. Variables d'environnement (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
2. Le fichier `~/.aws/credentials`, généré par la commande `aws configure` (celle qu'on a utilisée).
3. Un rôle IAM si on est déjà dans un environnement AWS (pas notre cas ici).

### Pourquoi c'est aussi important : l'incident qu'on a vécu

Pendant ce TP, une vraie erreur a été commise : une **Secret Access Key** (l'équivalent d'un mot de passe permettant d'agir sur tout un compte AWS) a été collée par erreur dans un fichier `.tf` (`key_name = "nbDQ/..."`, une valeur qui ressemblait à un nom de clé SSH mais était en réalité un secret). Deux leçons concrètes à en tirer :

1. **Une Secret Access Key ne doit jamais apparaître dans un fichier `.tf`, ni dans aucun fichier versionné.** Le seul endroit légitime, c'est `~/.aws/credentials` (en dehors du projet) ou un gestionnaire de secrets dédié en entreprise.
2. **Dès qu'une clé fuite (même dans un fichier local, même par erreur), il faut la désactiver/révoquer immédiatement dans AWS IAM et en générer une nouvelle.** Une clé exposée doit être considérée comme compromise, point final — c'est exactement ce qui a été fait ici.

### Authentification en pratique : `aws configure`

```
aws configure
```
Demande 4 valeurs : `AWS Access Key ID`, `AWS Secret Access Key`, `Default region name` (`eu-west-3`), `Default output format` (laissable vide). Ces deux premières valeurs proviennent d'un **utilisateur IAM** créé dans la console AWS (Identity and Access Management), avec des droits (une "policy") suffisants pour les actions du TP — dans notre cas, `AdministratorAccess` sur un compte personnel d'apprentissage.

Vérifier que ça fonctionne, sans rien exposer :
```
aws sts get-caller-identity
```
Cette commande interroge le service **STS** (Security Token Service) et répond "qui es-tu ?" — utile pour confirmer que les credentials sont valides *avant* de lancer `terraform plan`.

## Étape 2 — Première ressource réelle : un bucket S3

```hcl
resource "aws_s3_bucket" "learning" {
  bucket = "tf-learning-youssouf-2026-07-31"

  tags = {
    Name = "Terraform Learning Bucket"
    Env  = "formation"
  }
}
```

**S3** (Simple Storage Service) est le service de stockage de fichiers d'AWS — on peut y voir un "compartiment" (bucket) dans lequel ranger des fichiers, un peu comme un disque dur dans le cloud. On commence par S3 plutôt que par un serveur pour deux raisons : c'est gratuit dans les limites du free tier, et ça ne "tourne" pas en continu (pas de facturation à l'heure), contrairement à une VM.

**Piège à connaître** : le nom d'un bucket S3 doit être **unique dans le monde entier**, tous comptes AWS confondus — pas juste unique dans ton compte. C'est pour ça qu'on choisit un nom improbable (préfixe + nom + date).

**Erreur rencontrée en pratique** : AWS a refusé une `description` contenant une apostrophe (`d'apprentissage`) sur une autre ressource, avec le message d'erreur listant précisément les caractères autorisés. Beaucoup d'API cloud imposent ce genre de contraintes de formatage strictes — la lecture attentive du message d'erreur suffit presque toujours à comprendre quoi corriger.

## Étape 3 — Security Group et VPC par défaut

```hcl
resource "aws_security_group" "learning_sg" {
  name        = "tf-learning-sg"
  description = "Security group pour le module apprentissage"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-learning-sg"
  }
}
```

**VPC** (Virtual Private Cloud) : le réseau privé isolé dans lequel vivent toutes tes ressources AWS. Chaque compte a un **VPC par défaut** dans chaque région, créé automatiquement — inutile d'en créer un pour ce TP. Comme aucun `vpc_id` n'est précisé ici, AWS utilise ce VPC par défaut.

**Security Group** : un pare-feu virtuel qu'on attache à une ressource (ici, une VM juste après). Deux catégories de règles :
- **`ingress`** (entrant) : quel trafic a le droit d'**arriver** vers la ressource. Ici : uniquement du SSH (port 22), c'est la vraie surface d'exposition à surveiller — chaque port ouvert en entrée est un risque potentiel.
- **`egress`** (sortant) : quel trafic la ressource a le droit d'**envoyer** vers l'extérieur. Ici, tout est autorisé (`0.0.0.0/0`, tous ports) pour ne pas bloquer les installations de paquets, mises à jour, etc. (Nuance pour plus tard : sur un vrai projet en production, on restreint parfois aussi l'`egress`, pour limiter les dégâts si la VM était compromise.)

Chaque règle précise : un protocole (`tcp`, `udp`, ou `-1` pour "tous"), une plage de ports (`from_port`/`to_port`), et une origine/destination (`cidr_blocks` — `0.0.0.0/0` signifie "n'importe quelle adresse IP sur internet").

## Étape 4 — Générer une paire de clés SSH proprement (avec Terraform, pas à la main)

C'est la partie qui corrige directement l'erreur de sécurité vécue plus tôt. Au lieu de créer une clé SSH manuellement dans la console et de coller son nom (ou pire, un secret) en dur dans le code, on demande à **Terraform lui-même** de générer la clé et de l'enregistrer dans AWS.

```hcl
resource "tls_private_key" "learning_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "learning_key" {
  key_name   = "tf-learning-key"
  public_key = tls_private_key.learning_key.public_key_openssh
}

resource "local_file" "private_key" {
  filename        = "${path.module}/tf-learning-key.pem"
  content         = tls_private_key.learning_key.private_key_pem
  file_permission = "0600"
}
```

Rappel de cryptographie utile ici : une paire de clés SSH est composée de deux moitiés mathématiquement liées :
- une **clé publique** : sans danger à partager, c'est elle qu'on donne au serveur pour qu'il reconnaisse la bonne clé privée lors d'une connexion.
- une **clé privée** : le vrai secret, à ne **jamais** partager ni committer — c'est elle qui prouve ton identité lors de la connexion SSH.

Trois ressources travaillent ensemble :
1. `tls_private_key` (provider `tls`) : génère la paire clé publique/privée. Notez qu'aucune connexion à AWS n'est nécessaire pour cette étape — c'est un calcul purement local.
2. `aws_key_pair` (provider `aws`) : envoie uniquement la **clé publique** (`public_key_openssh`) à AWS, pour que ton compte "connaisse" cette clé et l'associe à une future VM. Logique : une clé publique n'a rien de secret.
3. `local_file` (provider `local`, revu au Module 1) : sauvegarde la **clé privée** sur le disque, avec `file_permission = "0600"` (seul le propriétaire du fichier peut le lire — une bonne pratique Unix classique pour tout fichier de clé privée).

**Détail observé dans le plan** : `terraform plan` affichait `content = (sensitive value)` pour la clé privée, au lieu de la montrer en clair. Le provider `tls` marque cet attribut comme sensible, et cette sensibilité **se propage** à toute ressource qui l'utilise ensuite (ici `local_file.private_key`). Ça protège l'affichage dans le terminal et les logs — **mais le fichier `terraform.tfstate`, lui, contient la vraie clé privée en clair**, ce qui renforce encore la règle "ne jamais commiter le state".

**Protection ajoutée au `.gitignore`** (à la racine du dossier `terraform-learning/`) :
```
*.pem
```
Pour être certain que le fichier de clé privée généré ne parte jamais sur GitHub, même par erreur d'inattention.

## Étape 5 — La VM (instance EC2)

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "learning_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.learning_sg.id]
  key_name               = aws_key_pair.learning_key.key_name

  tags = {
    Name = "tf-learning-server"
  }
}
```

**Nouveau concept : `data` au lieu de `resource`.** Une `data source` ne crée **rien** — elle **interroge** AWS pour récupérer des informations sur quelque chose qui existe déjà. Ici, `data "aws_ami" "ubuntu"` cherche, parmi toutes les images de VM ("AMI" = Amazon Machine Image) disponibles chez AWS, la plus récente (`most_recent = true`) qui correspond à Ubuntu 22.04 (via les `filter`), publiée par Canonical (l'éditeur officiel d'Ubuntu, identifié par son `owners`). Ça évite de coder en dur un identifiant d'AMI qui deviendrait obsolète (les AMI Ubuntu sont republiées régulièrement avec les derniers correctifs de sécurité).

**`aws_instance`** = la VM elle-même. On y retrouve tout ce qu'on a construit :
- `ami = data.aws_ami.ubuntu.id` : référence à la data source ci-dessus.
- `instance_type = var.instance_type` : le "gabarit" de la machine (CPU/RAM), défini par une variable — ici `t3.micro`, une petite instance à coût minime.
- `vpc_security_group_ids` : attache le Security Group de l'étape 3 (le pare-feu).
- `key_name = aws_key_pair.learning_key.key_name` : attache la paire de clés de l'étape 4. **Toute la chaîne est reliée par référence, jamais par valeur écrite en dur** — exactement ce qui manquait dans l'incident de sécurité initial.

## Étape 6 — L'output et la connexion SSH

```hcl
output "instance_public_ip" {
  description = "Adresse IP publique de la VM"
  value       = aws_instance.learning_server.public_ip
}
```

Une fois `terraform apply` terminé, l'IP publique s'affiche. On peut alors se connecter en SSH avec la clé privée générée à l'étape 4 :
```
ssh -i tf-learning-key.pem ubuntu@<IP_affichée>
```
(`ubuntu` est le nom d'utilisateur par défaut sur les images Ubuntu chez AWS.)

## Le coût, et pourquoi `terraform destroy` doit devenir un réflexe

Contrairement aux modules précédents, ces ressources (surtout l'instance EC2) peuvent avoir un **coût réel**, même minime pour un `t3.micro`. Contrairement à S3 (facturé au volume stocké), une VM est facturée **tant qu'elle tourne**, peu importe si elle est utilisée ou non. La discipline à adopter systématiquement en fin de session de travail :
```
terraform destroy
```

## Récapitulatif des commandes utilisées dans ce module

```
aws configure
aws sts get-caller-identity
terraform init
terraform plan
terraform apply
ssh -i tf-learning-key.pem ubuntu@<IP>
terraform destroy
```

## Ce qu'il faut retenir avant de passer à la suite

- Les credentials AWS ne vivent **jamais** dans un fichier `.tf` — uniquement dans `~/.aws/credentials` (ou un gestionnaire de secrets en entreprise).
- Une clé exposée par erreur doit être **révoquée immédiatement**, pas juste "retirée du code".
- `data` interroge l'existant, `resource` crée du nouveau — deux mécanismes différents mais qui se combinent naturellement.
- Générer une paire de clés SSH avec Terraform (`tls_private_key` + `aws_key_pair`) plutôt qu'à la main évite justement le genre de confusion vécue avec le TP initial.
- Une ressource facturée à l'usage (comme une VM) impose une discipline de nettoyage (`terraform destroy`) qu'une simple ressource de stockage n'impose pas de la même façon.
