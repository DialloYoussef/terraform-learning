# Module 2 — Aller plus loin en local

Objectif : dépasser la ressource unique du Module 1 pour apprendre à créer plusieurs ressources dynamiquement, factoriser des valeurs calculées, et sécuriser proprement un repo Terraform avant de passer au cloud. Toujours 100% local (provider `local`), aucun coût ni credential.

## Fichiers

- `main.tf` : déclare le provider `local`, un bloc `locals`, et une resource `local_file.note` créée dynamiquement via `for_each`.
- `variables.tf` : déclare la variable `environment` (`dev` par défaut).
- `note-*.txt` : fichiers générés par l'exercice (artefacts, pas indispensables à versionner).

## Concepts appris

### `count`

Première approche testée (remplacée ensuite par `for_each`, voir plus bas) : `count = 3` crée N copies identiques d'une ressource, indexées numériquement (`local_file.note[0]`, `[1]`, `[2]`). Référencement avec `count.index`.

**Limite découverte en pratique** : `count` identifie chaque ressource par sa **position** dans la liste, pas par son contenu. Modifier un élément au milieu d'une liste ne pose pas de problème (seul cet index est recréé), mais **retirer** un élément du milieu décale tous les index suivants — Terraform peut alors détruire/recréer des ressources qu'on voulait garder intactes. C'est la raison principale de préférer `for_each` dès que les éléments ont une identité propre.

### `for_each`

Remplace `count` par une itération sur une **map** (ou un `set`) à clés textuelles :

```hcl
resource "local_file" "note" {
  for_each = {
    intro    = "Ceci est l'introduction"
    concepts = "Ceci contient les concepts clés"
    exercice = "Ceci contient l'exercice pratique"
  }
  filename = "${path.module}/note-${each.key}.txt"
  content  = each.value
}
```

- `each.key` / `each.value` : la clé et la valeur de l'entrée courante.
- Référencement d'une ressource précise : `local_file.note["intro"]` (par clé, pas par index).
- Avantage : supprimer une entrée de la map ne touche **que** cette ressource, jamais les autres — contrairement à `count`.
- Passer de `count` à `for_each` change le mécanisme d'identification des ressources : Terraform détruit et recrée tout (visible dans le plan via `# (because resource does not use count)`), même si le contenu final est similaire.

### `locals`

Valeur calculée **à l'intérieur** du code (contrairement à une `variable`, fournie de l'extérieur) :

```hcl
locals {
  prefixe = var.environment == "prod" ? "PROD" : "DEV"
}
```

Référencée avec `local.nom` (singulier, même si le bloc s'appelle `locals`). Utile pour factoriser une expression réutilisée à plusieurs endroits, ou transformer une variable avant usage.

### Expressions conditionnelles (ternaire)

`condition ? valeur_si_vrai : valeur_si_faux` — ici utilisé pour faire varier `local.prefixe` selon `var.environment`, sans dupliquer le bloc `resource`. Testé en changeant uniquement la variable (`terraform plan -var="environment=prod"`), sans toucher au code : le plan bascule `[DEV]` ↔ `[PROD]` sur les 3 ressources.

### `.gitignore` Terraform

Vérifié que le `.gitignore` du repo (template standard Terraform) exclut bien `*.tfstate`, `.terraform/` et `*.tfvars` — confirmé via `git ls-files` qu'aucun de ces fichiers sensibles n'est suivi. C'est ce qui protège automatiquement contre un secret collé par erreur dans un `.tfvars`.

## Commandes clés utilisées

```
terraform init
terraform plan
terraform plan -var="environment=prod"
terraform apply
git ls-files
```
