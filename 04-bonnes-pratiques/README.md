# Module 4 — Bonnes pratiques

> Toujours 100% local (provider `local`), aucun coût. Ce module suppose les [Module 1](../01-bases-locales/README.md), [Module 2](../02-aller-plus-loin-en-local/README.md) et [Module 3](../03-aws/README.md) acquis.

## Pourquoi ce module

Les modules précédents t'ont donné les briques techniques (provider, resource, variables, `count`/`for_each`, provider AWS...). Celui-ci rassemble des **habitudes** à prendre systématiquement sur n'importe quel projet Terraform, quelle que soit sa taille — des réflexes qui évitent la plupart des incidents réels (fuite de secret, code dupliqué impossible à maintenir, ressources cloud oubliées qui coûtent de l'argent).

## `sensitive = true` : protéger l'affichage des valeurs secrètes

```hcl
variable "db_password" {
  description = "Mot de passe simulé d'une base de données"
  type        = string
  sensitive   = true
  default     = "SuperSecret123"
}
```

Une variable (ou un `output`) marquée `sensitive = true` ne s'affiche **jamais en clair** dans le terminal lors d'un `plan`/`apply` — Terraform la remplace par `(sensitive value)`. Un `output` sensible est masqué par défaut (`terraform output` seul l'affiche comme `<sensitive>`), sauf si on le cible explicitement par son nom (`terraform output db_password`).

**Ce que ça protège vraiment, et ce que ça ne protège pas** (point essentiel, vérifié en pratique) :
- ✅ Ça évite qu'un secret apparaisse par accident dans un log de CI/CD, une capture d'écran partagée, ou l'historique du terminal.
- ❌ Ça n'empêche **pas** le secret d'exister en clair dans `terraform.tfstate` — Terraform a besoin de connaître la vraie valeur pour gérer la ressource. Ça ne remplace donc pas les règles déjà vues : ne jamais commiter le state, toujours passer par `.gitignore`.
- ❌ Ce n'est **pas** un système de chiffrement. Pour un vrai secret de production (mot de passe de base de données, clé API...), l'outil adapté est un gestionnaire de secrets dédié (AWS Secrets Manager, HashiCorp Vault, etc.), pas une variable Terraform classique même marquée sensible.

## Les modules : réutiliser du code Terraform

Un **module**, c'est un dossier de fichiers `.tf` qu'on peut appeler plusieurs fois avec des valeurs différentes — le même principe qu'une fonction dans un langage de programmation classique : on écrit la logique une seule fois, on l'appelle avec des paramètres différents à chaque fois.

**Le module lui-même** (`modules/fichier-texte/`) ressemble à n'importe quel autre dossier Terraform qu'on a déjà écrit — il a ses `variables.tf`, `main.tf`, `outputs.tf` — à une différence près : il n'a pas besoin de son propre bloc `required_providers`, il hérite du provider déjà configuré par le projet qui l'appelle.

**L'appeler depuis le projet principal** :
```hcl
module "note_bienvenue" {
  source      = "./modules/fichier-texte"
  nom_fichier = "bienvenue.txt"
  contenu     = "Bienvenue dans les modules Terraform !"
}
```
- `source` : le chemin vers le module. Ici un chemin local (`./modules/...`), mais ça peut aussi être un module publié sur le [Terraform Registry](https://registry.terraform.io/browse/modules) ou un dépôt Git — dans ce cas, `terraform init` télécharge le code du module automatiquement, comme il le fait pour un provider.
- `note_bienvenue` : le nom de cette **instance** du module — libre à toi, comme un nom logique de resource.
- `nom_fichier` / `contenu` : les valeurs qu'on passe en entrée, correspondant aux `variable` déclarées dans le module.

Chaque appel crée ses propres ressources, préfixées dans le plan par `module.<nom_instance>.` — visible directement dans les logs : `module.note_bienvenue.local_file.fichier`, `module.note_recap.local_file.fichier`. Deux instances du même code, avec des paramètres différents.

**Pourquoi c'est utile en vrai** : imagine devoir créer 5 environnements identiques (dev, staging, prod...) avec la même structure de VM + Security Group + base de données, mais des noms/tailles différents. Sans module, il faudrait copier-coller tout le code 5 fois (et le maintenir 5 fois). Avec un module, on écrit la structure une fois, et on l'appelle 5 fois avec des paramètres différents.

## La discipline `terraform destroy`

Pas une nouvelle syntaxe, une **habitude** — pratiquée déjà plusieurs fois dans ce parcours, avec un enjeu concret au Module 3 (une VM EC2 qui tourne a un coût réel, même modeste).

**Checklist à suivre systématiquement en fin de session Terraform :**
1. `terraform state list` — lister d'un coup d'œil tout ce que Terraform gère actuellement dans ce dossier.
2. `terraform destroy` — relire le plan de suppression avant de confirmer, exactement comme pour un `apply` (rien n'est silencieux).
3. Vérifier dans la console du provider (AWS, etc.) que la ressource a bien disparu — ne pas se fier uniquement au message `Destroy complete!`.
4. Sur du cloud payant : garder en tête que Terraform ne peut nettoyer que ce qu'il connaît — une ressource créée manuellement en dehors de Terraform (à la main, dans la console) n'apparaîtra jamais dans `terraform state list`, et ne sera donc jamais supprimée par `destroy`.

Vérifié en pratique dans ce module : après `terraform destroy`, `terraform state list` ne retourne plus rien — confirmation qu'aucune ressource ne traîne.

## Récapitulatif des commandes utilisées dans ce module

```
terraform init
terraform plan
terraform apply
terraform output
terraform output <nom_sensible>
terraform state list
terraform destroy
```

## Ce qu'il faut retenir avant de clore ce parcours

- `sensitive = true` protège l'**affichage**, pas le **stockage** — le state reste le point sensible à protéger dans tous les cas.
- Un module = code réutilisable, appelé plusieurs fois avec des paramètres différents, préfixé `module.<instance>.` dans le state et les plans.
- `terraform destroy` + `terraform state list` (avant et après) doivent devenir un réflexe systématique, pas une action exceptionnelle.
