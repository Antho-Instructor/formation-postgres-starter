# Mémo PL/pgSQL

## Squelette d'un bloc

```sql
DO $$
DECLARE
  v_total int;
BEGIN
  SELECT count(*) INTO v_total FROM serveur;
  RAISE NOTICE '% serveurs', v_total;
END $$;
```

Dans une fonction, le même bloc devient le corps entre `$$` :

```sql
CREATE OR REPLACE FUNCTION double(p_valeur int DEFAULT 10)
RETURNS int
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN p_valeur * 2;
END $$;
```

## Variables

```sql
DECLARE
  v_entier  int := 0;
  v_texte   text;
  v_ligne   serveur%ROWTYPE;      -- une ligne entière, typée sur la table
  v_specs   serveur.specs%TYPE;   -- le type d'une colonne
  r         record;               -- une ligne de structure quelconque
```

```sql
SELECT nom INTO v_texte FROM serveur WHERE id = 1;
PERFORM 1 FROM serveur WHERE id = 1;   -- exécute sans garder le résultat
```

`FOUND` vaut `true` si le dernier `SELECT INTO`, `PERFORM`, `INSERT`, `UPDATE` ou `DELETE` a trouvé ou touché au moins une ligne. Un `SELECT INTO` sans résultat ne lève pas d'erreur : testez `FOUND`.

```sql
GET DIAGNOSTICS v_entier = ROW_COUNT;   -- lignes touchées par la dernière instruction
```

## Contrôle

```sql
IF condition THEN
  ...
ELSIF autre_condition THEN
  ...
ELSE
  ...
END IF;

FOR i IN 1..10 LOOP ... END LOOP;

FOR r IN SELECT id, nom FROM serveur LOOP
  RAISE NOTICE '%', r.nom;
END LOOP;

LOOP
  EXIT WHEN condition;
  ...
END LOOP;
```

## Messages et erreurs

```sql
RAISE NOTICE 'Serveur % : % %%', v_nom, v_taux;   -- % = valeur, %% = signe pourcentage

RAISE EXCEPTION 'Serveur % inconnu', p_id
  USING ERRCODE = 'no_data_found',
        HINT = 'Vérifiez l''identifiant.';

BEGIN
  ...
EXCEPTION
  WHEN unique_violation THEN ...
  WHEN OTHERS THEN
    RAISE NOTICE 'Erreur % : %', SQLSTATE, SQLERRM;
END;
```

Un `RAISE EXCEPTION` non intercepté annule toute la transaction. Une section `EXCEPTION` crée un point de sauvegarde à chaque entrée dans le bloc : seules les modifications du bloc sont annulées, mais cela a un coût.

| SQLSTATE | Nom | Cas |
|---|---|---|
| `23505` | `unique_violation` | Doublon sur une contrainte UNIQUE |
| `23503` | `foreign_key_violation` | Clé étrangère |
| `23P01` | `exclusion_violation` | Contrainte EXCLUDE |
| `42501` | `insufficient_privilege` | Droits insuffisants |
| `P0001` | `raise_exception` | `RAISE EXCEPTION` sans `ERRCODE` |

## Fonction ou procédure ?

| | Fonction | Procédure |
|---|---|---|
| Appel | Dans une requête : `SELECT f()` | `CALL p()` |
| Renvoie | Une valeur, une ligne ou une table | Rien (ou des paramètres `INOUT`) |
| `COMMIT` / `ROLLBACK` à l'intérieur | Impossible | Possible, sauf si le `CALL` est dans un `BEGIN` explicite |

## Volatilité

| Mot-clé | Promesse | Exemple |
|---|---|---|
| `IMMUTABLE` | Même résultat pour mêmes arguments, toujours, sans lire la base | `lower()` |
| `STABLE` | Même résultat pendant une requête, peut lire la base | `now()` |
| `VOLATILE` (défaut) | Aucune promesse | `random()` |

Seule une fonction `IMMUTABLE` peut servir dans un index.

## SECURITY DEFINER

```sql
CREATE FUNCTION f() RETURNS bigint
LANGUAGE sql STABLE
SECURITY DEFINER                   -- s'exécute avec les droits du propriétaire
SET search_path = public, pg_temp  -- indispensable : empêche le détournement
AS $$ SELECT count(*) FROM mesure $$;

REVOKE EXECUTE ON FUNCTION f() FROM PUBLIC;   -- par défaut, tout le monde peut l'exécuter
GRANT EXECUTE ON FUNCTION f() TO support;
```

## Triggers

```sql
CREATE OR REPLACE FUNCTION horodater() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.modifie_le := now();
  RETURN NEW;
END $$;

CREATE TRIGGER trg_horodater
BEFORE UPDATE ON serveur
FOR EACH ROW EXECUTE FUNCTION horodater();
```

| Ce qui est disponible | Contenu |
|---|---|
| `NEW` | La nouvelle ligne (`INSERT`, `UPDATE`) |
| `OLD` | L'ancienne ligne (`UPDATE`, `DELETE`) |
| `TG_OP` | `'INSERT'`, `'UPDATE'`, `'DELETE'` ou `'TRUNCATE'` |
| `TG_TABLE_NAME` | La table qui a déclenché le trigger |

| Type de trigger | Valeur de retour |
|---|---|
| `BEFORE ... FOR EACH ROW` | `NEW` pour écrire la ligne. `NULL` abandonne l'opération, sans erreur |
| `AFTER ... FOR EACH ROW` | Ignorée |
| `FOR EACH STATEMENT` | Ignorée. Les lignes sont dans les tables de transition (`REFERENCING NEW TABLE AS ...`) |
