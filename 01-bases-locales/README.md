# Module 1 — Bases locales

Objectif : comprendre la syntaxe HCL, le cycle de vie Terraform et les variables/outputs, sans toucher à aucun cloud (provider `local`, aucun coût, aucun credential).

## Fichiers

- `main.tf` : déclare le provider `local` et une resource `local_file.hello` qui écrit un fichier sur disque.
- `variables.tf` : déclare la variable `message` (avec valeur par défaut).
- `terraform.tfvars` : fournit une valeur pour `message`, chargée automatiquement par Terraform.
- `outputs.tf` : expose `fichier_cree` (chemin du fichier) et `hash_du_contenu` (SHA256) après un `apply`.

## Concepts appris

**Provider** : le plugin qui sait parler à un système donné (ici `local`, plus tard `aws`). Déclaré dans un bloc `terraform { required_providers { ... } }`, téléchargé par `terraform init`.

**Resource** : une chose concrète que Terraform crée/gère. Syntaxe : `resource "<type>" "<nom_logique>" { ... }`. Le nom logique (`hello`) est choisi par nous, sert à référencer la ressource ailleurs dans le code (`local_file.hello.filename`).

**Cycle de vie** :
- `terraform init` : télécharge les providers requis, crée `.terraform.lock.hcl` (à commiter — fige les versions).
- `terraform plan` : calcule et affiche les changements à venir, **sans rien exécuter**. Symboles : `+` créer, `~` modifier en place, `-/+` détruire puis recréer, `-` détruire.
- `terraform apply` : exécute réellement le plan (demande confirmation `yes`).
- `terraform destroy` : supprime tout ce que Terraform gère dans ce dossier.

**State (`terraform.tfstate`)** : mémoire de Terraform — ce qu'il a créé et les valeurs réelles de chaque ressource. **Ne jamais commiter ce fichier dans Git** (peut contenir des secrets ; sur un vrai projet il est stocké dans un backend distant partagé, pas en local). `terraform.tfstate.backup` est une sauvegarde automatique de l'état précédent.

**Refresh & drift** : avant de comparer, Terraform relit l'état réel (`Refreshing state...`) pour détecter si quelque chose a changé en dehors de lui (le "drift").

**Update en place vs remplacement** : certains changements se font sans destruction (`~` simple), d'autres forcent un `destroy` + `create` (`# forces replacement` dans le plan). Ça dépend du provider/attribut — pour `local_file`, changer `content` force toujours un remplacement. **Toujours vérifier ce détail dans le plan avant de confirmer**, surtout sur une vraie infra.

**Variables** :
- Déclarées dans `variables.tf` avec `variable "nom" { type = ...; default = ...; description = ... }`.
- Référencées avec `var.nom` dans le reste du code.
- Fournies par ordre de priorité croissante : `default` < `terraform.tfvars` (chargé automatiquement) < flag `-var="nom=valeur"` en ligne de commande.

**Outputs** :
- Déclarés dans `outputs.tf` avec `output "nom" { value = ... }`.
- Affichés après `apply`, consultables à tout moment avec `terraform output`.

## Commandes clés utilisées

```
terraform init
terraform plan
terraform plan -var="message=..."
terraform apply
terraform output
terraform destroy
```
