# Module 2 — Créer plusieurs ressources et factoriser du code

> Toujours 100% local (provider `local`), aucun coût ni credential. Ce module part du principe que tu as lu le [README du Module 1](../01-bases-locales/README.md) — les bases (provider, resource, cycle de vie, state, variables, outputs) ne sont pas réexpliquées ici en détail.

## Pourquoi ce module existe

Dans le Module 1, on créait **une seule** ressource. En pratique, on a très souvent besoin de créer **plusieurs choses similaires** : plusieurs fichiers de config, plusieurs serveurs identiques, plusieurs comptes utilisateurs... Copier-coller le bloc `resource` autant de fois que nécessaire fonctionnerait, mais ce n'est pas maintenable (si tu dois changer un détail commun à toutes les copies, il faut le répéter partout). Terraform propose deux mécanismes pour éviter ça : `count` et `for_each`.

## `count` : la première approche (et ses limites)

```hcl
resource "local_file" "note" {
  count    = 3
  filename = "${path.module}/note-${count.index}.txt"
  content  = "Ceci est la note numéro ${count.index}"
}
```

- `count = 3` : demande à Terraform de créer **3 copies** de cette ressource.
- `count.index` : une variable spéciale, disponible uniquement à l'intérieur d'une ressource qui utilise `count`. Elle vaut `0` pour la première copie, `1` pour la deuxième, `2` pour la troisième, etc. — on s'en sert pour différencier chaque copie (ici, dans le nom du fichier et le contenu).
- Résultat dans le state : `local_file.note[0]`, `local_file.note[1]`, `local_file.note[2]` — trois ressources **distinctes**, chacune identifiée par son **index numérique** (sa position).

### Le problème concret qu'on a observé

Tant qu'on ne fait que **modifier** un élément (par exemple changer le contenu de l'élément d'index 1), tout va bien : seul cet élément est recréé, les autres ne bougent pas.

Le vrai problème apparaît quand on **retire un élément qui n'est pas le dernier**. Exemple concret : imagine 3 serveurs `[0, 1, 2]`, et tu veux supprimer celui du milieu pour n'en garder que 2. Terraform ne raisonne que par position numérique — il ne sait pas que "l'élément 2" était en réalité différent de "l'élément 1". En recalculant les positions, il risque de considérer que l'ancien élément à la position 2 doit maintenant occuper la position 1, et donc de **détruire et recréer un serveur que tu voulais pourtant garder intact**. C'est un piège classique et une source de bugs difficiles à repérer dans un vrai projet.

## `for_each` : la solution recommandée dans la plupart des cas

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

- `for_each` prend une **map** (paires clé-valeur) au lieu d'un simple nombre. Ici : `intro`, `concepts`, `exercice` sont des **clés textuelles**, choisies par toi et porteuses de sens (contrairement à un index numérique qui ne veut rien dire en soi).
- `each.key` : la clé de l'entrée courante (ex: `"intro"`). `each.value` : la valeur associée (ex: `"Ceci est l'introduction"`).
- Résultat dans le state : `local_file.note["intro"]`, `local_file.note["concepts"]`, `local_file.note["exercice"]` — identifiés par **clé**, pas par position.

**Pourquoi c'est plus sûr** : si tu retires `"concepts"` de la map, Terraform sait précisément que c'est *cette* ressource-là (et seulement celle-là) qu'il faut supprimer. `"intro"` et `"exercice"` ne sont jamais touchées, peu importe leur ordre dans le fichier. C'est pour cette raison qu'on privilégie `for_each` dès que les éléments créés ont une identité propre (des noms, des rôles différents) — et qu'on garde `count` seulement pour de vraies copies interchangeables (par exemple, "je veux 3 serveurs strictement identiques, peu importe lequel est lequel").

**Détail technique observé en pratique** : passer de `count` à `for_each` sur la même ressource force Terraform à tout détruire et recréer, même si le contenu final est similaire — parce que le *mécanisme d'identification* change complètement (index → clé), ce ne sont pas des ressources "renommées" aux yeux de Terraform, mais des ressources différentes.

## `locals` : factoriser une valeur calculée

Une **variable** (`variable`) est une valeur fournie **de l'extérieur** (par un `.tfvars`, un flag, ou une valeur par défaut). Un **local** (`locals`) est une valeur **calculée à l'intérieur** du code, à partir d'autres valeurs — utile pour éviter de répéter une même expression à plusieurs endroits, ou pour donner un nom clair à un calcul.

```hcl
locals {
  prefixe = var.environment == "prod" ? "PROD" : "DEV"
}
```

Point de syntaxe à ne pas manquer : le bloc s'appelle `locals` (avec un "s"), mais on le référence ensuite avec `local.nom` (**sans** "s") — ici `local.prefixe`.

## Les expressions conditionnelles (l'opérateur ternaire)

`condition ? valeur_si_vrai : valeur_si_faux` — la même logique qu'un `if/else` court, présente dans la plupart des langages de programmation. Dans l'exemple ci-dessus : *si* `var.environment` vaut exactement `"prod"`, *alors* `local.prefixe` vaut `"PROD"`, *sinon* il vaut `"DEV"`.

On a vérifié en pratique que ça fonctionne en changeant uniquement la variable, sans toucher au code :
```
terraform plan                              # environment vaut "dev" par défaut → [DEV]
terraform plan -var="environment=prod"      # → [PROD]
```

## Le `.gitignore` Terraform : pourquoi il est indispensable

On a vérifié le contenu du `.gitignore` de ce repo (généré automatiquement, c'est le modèle standard recommandé par Terraform) et confirmé — avec la commande `git ls-files` — qu'aucun fichier sensible n'est suivi par Git. Les lignes clés :

```
.terraform/       # dossier téléchargé par `init` — se régénère, jamais utile de le versionner
*.tfstate         # le state — peut contenir des secrets en clair (vu au Module 1)
*.tfvars          # fichiers de valeurs — souvent utilisés pour des mots de passe, clés API, etc.
```

C'est une protection **automatique** : même si, par erreur, on collait un mot de passe dans un fichier `.tfvars`, ce fichier ne partirait jamais sur GitHub grâce à cette règle. C'est le genre de filet de sécurité qu'on doit vérifier en début de projet, pas découvrir après coup.

## Récapitulatif des commandes utilisées dans ce module

```
terraform init
terraform plan
terraform plan -var="environment=prod"
terraform apply
git ls-files
```

## Ce qu'il faut retenir avant de passer au module suivant

- `count` identifie par **position** (fragile si la liste change) ; `for_each` identifie par **clé** (robuste). Par défaut, penser `for_each` en premier.
- `locals` = calcul interne, réutilisable, à ne pas confondre avec `variable` (qui vient de l'extérieur).
- Les expressions conditionnelles permettent de faire varier une valeur sans dupliquer de code.
- Un `.gitignore` Terraform bien configuré est une protection de base contre la fuite de secrets — à vérifier systématiquement, pas à ajouter "si on y pense".
