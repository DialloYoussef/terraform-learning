# Roadmap — Apprentissage Terraform (A → Z)

Parcours pédagogique, étape par étape. On coche au fur et à mesure.

## Partie 1 — Bases locales (sans cloud)
- [x] 1. Syntaxe HCL, providers, resources (`local`, `random`)
- [x] 2. Cycle de vie : `init` → `plan` → `apply` → `destroy`, et `terraform.tfstate`
- [x] 3. Variables (`variables.tf`), `terraform.tfvars`, types, valeurs par défaut
- [x] 4. Outputs, interpolation, fonctions intégrées

## Partie 2 — Aller plus loin en local
- [x] 5. `count` / `for_each`
- [x] 6. Expressions conditionnelles, `locals`
- [x] 7. Structure de fichiers standard + `.gitignore` Terraform

## Partie 3 — Transition vers AWS
- [x] 8. Provider AWS, authentification (bonnes pratiques credentials)
- [x] 9. Première ressource AWS simple (ex: S3 bucket)
- [x] 10. Security Groups, VPC par défaut
- [x] 11. Instance EC2 (relire le TP du prof avec les acquis)

## Partie 4 — Bonnes pratiques
- [x] 12. Gestion des secrets (`.tfvars` ignoré par git, `sensitive = true`)
- [x] 13. Introduction aux modules
- [ ] 14. Discipline `terraform destroy` systématique
