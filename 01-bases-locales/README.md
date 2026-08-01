# Module 1 — Les bases de Terraform (à partir de zéro)

> Ce module ne touche à aucun service cloud (pas d'AWS, pas de compte, pas de coût). On utilise uniquement le disque dur de la machine, pour apprendre la mécanique de Terraform sans risque.

## C'est quoi, Terraform, et pourquoi ça existe ?

Avant Terraform, pour créer un serveur, une base de données ou un réseau chez un fournisseur cloud (AWS, Azure, Google Cloud...), on cliquait manuellement dans une console web, étape par étape. Problème : ce n'est pas reproductible (si on doit refaire la même chose demain, ou sur un autre compte, il faut re-cliquer partout à la main), pas versionnable (aucun historique de "qui a changé quoi"), et source d'erreurs humaines.

**Terraform** appartient à une famille d'outils appelée **Infrastructure as Code** (IaC) : "l'infrastructure comme du code". L'idée : au lieu de cliquer, on **écrit dans un fichier texte** ce qu'on veut ("je veux un serveur, avec telle configuration"), et un programme (Terraform) se charge de créer/modifier/supprimer les vraies ressources pour que la réalité corresponde à ce texte.

Analogie : c'est la différence entre donner des instructions orales à un ouvrier à chaque étape ("pose une brique ici, puis une autre là...") et lui donner un **plan d'architecte** qu'il suit et peut reproduire à l'identique n'importe où.

Le langage utilisé par Terraform s'appelle le **HCL** (HashiCorp Configuration Language). C'est ce qu'il y a dans les fichiers `.tf`.

## Vocabulaire de base (à connaître par cœur)

| Terme | Définition simple |
|---|---|
| **Provider** | Un "plugin" qui sait parler à un système précis. Dans ce module : `local` (le disque dur de ta machine). Plus tard : `aws`, `docker`, etc. |
| **Resource** | Une chose concrète que Terraform va créer et gérer pour toi (un fichier, plus tard un serveur, une base de données...). |
| **State** (`terraform.tfstate`) | Le "carnet de mémoire" de Terraform : ce qu'il a réellement créé, avec les vraies valeurs. |
| **Variable** | Une valeur qu'on peut faire varier de l'extérieur, sans modifier le code (ex: choisir le contenu d'un fichier). |
| **Output** | Une information que Terraform affiche à la fin, pratique pour récupérer un résultat (ex: une adresse IP). |

## Les fichiers de ce module

- **`main.tf`** : le fichier principal, où on déclare le provider et la ressource.
- **`variables.tf`** : où on déclare les variables utilisables dans `main.tf`.
- **`terraform.tfvars`** : où on donne une valeur concrète à ces variables (chargé automatiquement par Terraform, pas besoin de préciser son nom nulle part).
- **`outputs.tf`** : où on déclare ce que Terraform doit afficher après avoir travaillé.

Il n'y a **aucune règle stricte** sur ces noms de fichiers — Terraform lit en réalité *tous* les fichiers `.tf` du dossier comme s'ils n'en formaient qu'un seul. On les sépare par nom uniquement parce que c'est une convention largement adoptée, qui rend le code plus facile à lire pour quelqu'un d'autre (ou pour toi, six mois plus tard).

## Étape par étape : ce qu'on a fait, et pourquoi

### 1. Déclarer un provider et une resource

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Bonjour depuis Terraform !"
}
```

Décortiquons ligne par ligne :

- `terraform { required_providers { ... } }` : ce bloc dit à Terraform "voici les providers dont j'ai besoin, va les télécharger". `source = "hashicorp/local"` pointe vers le [Terraform Registry](https://registry.terraform.io) (une sorte de "magasin d'applications" pour les providers). `version = "~> 2.5"` fige une plage de versions acceptées, pour éviter qu'une mise à jour automatique ne casse le projet sans prévenir.
- `resource "local_file" "hello" { ... }` : la syntaxe générale d'une resource est toujours `resource "<type>" "<nom_que_tu_choisis>" { <arguments> }`.
  - `"local_file"` = le **type** de ressource. Il est défini par le provider `local` — chaque provider fournit une liste de types possibles (documentée sur le Registry).
  - `"hello"` = le **nom logique**, choisi librement par toi. Il sert à référencer cette ressource ailleurs dans ton code, par exemple `local_file.hello.filename`. Ce n'est *pas* le nom du fichier réel — juste une étiquette interne à Terraform.
  - `filename` et `content` = les **arguments** propres à ce type de ressource (chaque type a sa propre liste d'arguments, à chercher dans la doc du provider si besoin).
  - `${path.module}` = une variable spéciale intégrée à Terraform, qui vaut "le dossier où se trouve ce fichier `.tf`". Ça évite d'écrire un chemin absolu en dur.

### 2. Le cycle de vie : les 4 commandes qu'on utilise tout le temps

```
terraform init      # (1) préparer le dossier
terraform plan       # (2) prévisualiser ce qui va se passer
terraform apply       # (3) exécuter réellement
terraform destroy     # (4) tout supprimer
```

**`terraform init`** : à lancer une seule fois par dossier de projet (ou à chaque fois qu'on ajoute un nouveau provider). Elle télécharge les providers déclarés et crée deux choses :
  - un dossier caché `.terraform/` (les fichiers du plugin téléchargé — jamais à toucher ni à commiter dans git).
  - un fichier `.terraform.lock.hcl` (fige les versions exactes téléchargées — **celui-là, on le commit**, pour que tout le monde utilise exactement la même version du provider).

**`terraform plan`** : calcule et affiche ce que Terraform *compte faire*, **sans rien exécuter**. C'est une simulation. Toujours la lire avant d'appliquer, en vrai projet une erreur ici peut éviter une catastrophe (ex: supprimer une base de données par accident). Les symboles à connaître :
  - `+` : la ressource sera **créée**.
  - `~` : la ressource sera **modifiée en place** (sans interruption).
  - `-` : la ressource sera **supprimée**.
  - `-/+` : la ressource sera **détruite puis recréée** (donc une interruption, parfois une perte de données si ce n'est pas juste un fichier texte). On voit apparaître un commentaire `# forces replacement` sur l'attribut responsable.

**`terraform apply`** : exécute réellement le plan. Terraform te réaffiche le plan et **demande une confirmation explicite** (taper `yes`) avant de toucher à quoi que ce soit — aucune action n'est silencieuse.

**`terraform destroy`** : supprime tout ce que Terraform gère dans ce dossier (selon ce qu'il y a dans le state). Réflexe à prendre en fin de session, surtout sur du cloud payant.

### 3. Le state : la mémoire de Terraform

Après un `apply`, un fichier `terraform.tfstate` apparaît. C'est un fichier JSON qui liste tout ce que Terraform a créé, avec les vraies valeurs (y compris des empreintes de contenu comme `content_md5`, utilisées pour détecter des changements).

**Règle absolue à retenir : on ne commit JAMAIS ce fichier dans Git.** Deux raisons :
1. Il peut contenir des **secrets en clair** (mots de passe générés, clés privées — on l'a vérifié nous-mêmes plus tard avec une vraie clé SSH).
2. Sur un vrai projet en équipe, le state est partagé via un système dédié (ex: un bucket S3 avec verrouillage), jamais via Git — sinon deux personnes qui travaillent en même temps se marchent dessus et corrompent l'état partagé.

Un fichier `terraform.tfstate.backup` apparaît aussi : une sauvegarde automatique de l'état juste avant la dernière opération, un filet de sécurité.

**Le "refresh" et le drift** : avant de comparer ton code à la réalité, Terraform relit toujours l'état réel (`Refreshing state...` dans les logs). Ça sert à détecter le **drift** : si quelqu'un a modifié la ressource *en dehors* de Terraform (à la main, par exemple), Terraform le remarque et te le signale au prochain `plan`.

**Update en place VS remplacement** : on l'a vu concrètement — changer le `content` d'un `local_file` force une destruction + recréation complète (`-/+`), parce que le provider `local` ne sait pas "éditer" un fichier existant, seulement le remplacer. Ce comportement dépend entièrement du provider et de l'attribut modifié : plus tard sur AWS, changer un simple tag se fera en place, mais changer le type d'une VM forcera un remplacement complet. **Toujours vérifier ce détail dans le `plan` avant de confirmer**, car un remplacement peut vouloir dire une coupure de service sur un vrai projet.

### 4. Les variables : ne plus écrire de valeurs en dur

Sans variable, si on veut changer `"Bonjour depuis Terraform !"`, il faut éditer `main.tf` directement — pas pratique si plusieurs personnes utilisent le même code avec des besoins différents.

**Déclarer une variable** (dans `variables.tf`) :
```hcl
variable "message" {
  description = "Contenu écrit dans le fichier"
  type        = string
  default     = "Bonjour depuis Terraform !"
}
```
- `type = string` : Terraform refusera toute autre chose qu'une chaîne de caractères (les autres types courants : `number`, `bool`, `list(...)`, `map(...)`).
- `default` : la valeur utilisée si on ne fournit rien d'autre. Optionnel — sans `default`, Terraform **demandera** la valeur à chaque `plan`/`apply` (pratique pour forcer une saisie volontaire, gênant si on veut tout automatiser).
- `description` : un simple commentaire pour les humains, affiché par exemple dans `terraform plan` si la variable n'a pas de valeur.

**Utiliser la variable** (dans `main.tf`), avec le préfixe `var.` :
```hcl
content = var.message
```

**Fournir une valeur différente**, trois façons possibles, classées par priorité **croissante** (la dernière l'emporte sur les précédentes) :
1. `default` dans `variables.tf` — la valeur de repli si rien d'autre n'est fourni.
2. `terraform.tfvars` — un fichier chargé **automatiquement** par Terraform (pas besoin de flag), pratique pour la valeur "habituelle" d'un projet :
   ```hcl
   message = "Valeur depuis terraform.tfvars"
   ```
3. Le flag `-var="nom=valeur"` en ligne de commande — utile pour un test ponctuel ou un script CI, sans toucher aux fichiers :
   ```
   terraform plan -var="message=Test avec override"
   ```

### 5. Les outputs : afficher un résultat utile

Un `output` sert à faire ressortir une information après un `apply` — typiquement une valeur qu'on ne connaît qu'une fois la ressource réellement créée (comme l'adresse IP d'un serveur, qu'on verra dans le Module 3).

```hcl
output "fichier_cree" {
  description = "Chemin du fichier généré"
  value       = local_file.hello.filename
}
```

Syntaxe pour référencer un attribut d'une ressource : `<type>.<nom_logique>.<attribut>` — ici `local_file.hello.filename`. C'est le même principe partout dans Terraform : une fois qu'une ressource a un nom logique, on peut piocher n'importe lequel de ses attributs ailleurs dans le code.

Les outputs s'affichent automatiquement après `apply`, et on peut les revoir à tout moment sans relancer un apply :
```
terraform output
```

## Récapitulatif des commandes utilisées dans ce module

```
terraform init
terraform plan
terraform plan -var="message=..."
terraform apply
terraform output
terraform destroy
```

## Ce qu'il faut retenir avant de passer au module suivant

- Terraform ne fait **jamais** rien sans qu'on lui demande explicitement (`plan` = simulation, `apply` = confirmation requise).
- Le **state** est la mémoire de Terraform, ne jamais le commiter, ne jamais le modifier à la main.
- **Variables** = valeurs qui viennent de l'extérieur ; **outputs** = valeurs qu'on fait sortir vers l'extérieur.
- Toujours lire le `plan` avant de confirmer, en particulier regarder si une ressource sera modifiée en place ou détruite/recréée.
