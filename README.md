# terraform-learning

Parcours d'apprentissage Terraform, construit **from scratch**, module par module, en exécutant réellement chaque commande (pas juste en lisant de la théorie). Chaque module a son propre dossier avec un `README.md` détaillé — pensé pour être compréhensible même sans expérience préalable de Terraform.

Ce repo est indépendant du TP fourni par le formateur (voir `../tp-docker/terraform/`) : il sert à consolider les bases avant d'y revenir avec plus de recul.

## Pourquoi Terraform, en une phrase

Terraform est un outil d'**Infrastructure as Code** : au lieu de créer des serveurs/réseaux/services cloud en cliquant manuellement dans une console, on décrit ce qu'on veut dans des fichiers texte (`.tf`), et Terraform se charge de créer/modifier/supprimer les vraies ressources pour que la réalité corresponde à ce texte — de façon reproductible et versionnable.

## Prérequis pour suivre ce parcours

- **Terraform** installé et accessible dans le `PATH` (vérifier avec `terraform -version`).
- **AWS CLI** installé (vérifier avec `aws --version`) — nécessaire uniquement à partir du Module 3.
- Un compte AWS avec un utilisateur IAM disposant des droits nécessaires, et ses credentials configurées via `aws configure` — nécessaire uniquement à partir du Module 3.

Aucun de ces prérequis n'est nécessaire pour les Modules 1 et 2 (100% locaux, aucun compte cloud).

## Parcours

Le détail complet, coché au fur et à mesure, est dans [`ROADMAP.md`](ROADMAP.md). Résumé par module :

| Dossier | Sujet | Prérequis cloud |
|---|---|---|
| [`01-bases-locales/`](01-bases-locales/README.md) | Provider, resource, cycle de vie (`init`/`plan`/`apply`/`destroy`), state, variables, outputs | Aucun |
| [`02-aller-plus-loin-en-local/`](02-aller-plus-loin-en-local/README.md) | `count` vs `for_each`, `locals`, expressions conditionnelles, `.gitignore` Terraform | Aucun |
| [`03-aws/`](03-aws/README.md) | Provider AWS, authentification, S3, Security Group, génération de clé SSH via Terraform, instance EC2 | Compte AWS |

Chaque `README.md` de module est autonome : il explique le vocabulaire utilisé, décortique chaque ligne de code écrite, et documente les erreurs réellement rencontrées en cours de route (avec leur explication) plutôt que de rester purement théorique.

## Comment suivre un module

Dans chaque dossier de module :
```
terraform init      # télécharge les providers nécessaires
terraform plan       # prévisualise les changements, sans rien exécuter
terraform apply       # applique réellement (demande confirmation)
terraform destroy     # supprime tout ce qui a été créé dans ce module
```

Réflexe à prendre systématiquement en fin de session sur le Module 3 (AWS) : `terraform destroy`, pour éviter de laisser tourner des ressources facturées inutilement.

## Sécurité — règles non négociables suivies dans tout ce repo

- Aucune clé d'accès (`AWS_SECRET_ACCESS_KEY` ou équivalent) n'apparaît jamais dans un fichier `.tf` ou `.tfvars` versionné.
- Le fichier `terraform.tfstate` (mémoire de Terraform, peut contenir des secrets en clair) n'est jamais commité — voir `.gitignore`.
- Toute clé SSH nécessaire à une ressource cloud est **générée par Terraform lui-même** (voir Module 3), jamais collée à la main.
- Toute clé exposée par erreur est considérée comme compromise et doit être révoquée immédiatement dans AWS IAM.
