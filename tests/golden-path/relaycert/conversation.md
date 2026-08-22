# RelayCert reference conversation

## 1. Opening

**Calm**

Tell me what you’re building, where you are today, and what feels hardest right now. Write naturally — I’ll ask only what I need.

## 2. Founder intake

**Founder**

Je construis RelayCert. J'ai travaillé sept ans dans les opérations d'une
entreprise de maintenance incendie et je voyais tout le temps les assistantes
courir après les techniciens pour récupérer une signature, une référence ou
une photo avant de pouvoir envoyer le certificat et parfois la facture.

J'ai bricolé un produit qui donne une checklist au technicien et une vue des
dossiers incomplets au bureau. Deux entreprises d'amis le testent gratuitement,
mais je ne sais pas encore si le problème est assez important pour qu'elles
paient. Je pense que je dois vendre au dirigeant, mais l'assistante ou la
coordinatrice est probablement celle qui l'utilise tous les jours.

Aujourd'hui, elles suivent les dossiers ouverts dans un tableur ou un dossier
partagé, puis relancent les techniciens par téléphone, WhatsApp ou email.

Le site dit 149 € par mois, mais honnêtement c'est un chiffre choisi au hasard.
Je peux consacrer environ douze heures par semaine au projet et 1 000 € sur les
trois prochains mois. Je ne veux pas lever des fonds. Si j'arrive à construire
une activité rentable avec 25 clients dans les douze prochains mois, ce serait
déjà une vraie réussite.

Ce qui me bloque : je ne sais pas si je dois parler de conformité, de temps
administratif ou de factures envoyées plus vite, et je ne sais pas qui cibler en
premier.

J'ai mis une copie du site dans `fixtures/website.html` et mes notes des deux
pilotes dans `fixtures/pilot-notes.md`.

## 3. Reflection and material questions

**Calm**

Voici ce que je pense qu'il se passe :

Tu construis RelayCert pour des entreprises de maintenance incendie. Le
problème le plus concret semble être le délai entre une intervention terminée
et un dossier suffisamment complet pour envoyer le certificat puis la facture.
Ton expérience métier et les notes que tu as fournies sur les deux pilotes
indiquent que ce problème existe, mais elles ne prouvent pas encore qu'il est
prioritaire ni qu'un client paiera pour le résoudre. Le prix de 149 € affiché
sur le site reste une hypothèse.

Il y a deux choses que je dois comprendre avant de recommander le GTM :

1. Dans les deux entreprises pilotes, qui souffre le plus du problème au
   quotidien, et qui peut décider de payer ?
2. Quelle conséquence précise ferait dire au dirigeant « cela vaut un pilote
   payant » : moins de relances, moins de risque de conformité, ou des factures
   envoyées plus vite ?

## 4. Founder clarification

**Founder**

Dans les deux cas, c'est l'assistante ou la coordinatrice d'exploitation qui
relance les techniciens. Le dirigeant décide des outils et paie. Les deux me
parlent des trois problèmes, mais dès qu'une facture reste bloquée plusieurs
jours, le dirigeant s'en mêle. Donc je pense que la facture est la conséquence
la plus urgente et que la conformité est plutôt la raison pour laquelle le
dossier doit être complet.

Aucun des deux ne paie aujourd'hui. Un dirigeant m'a dit qu'il pourrait payer
300 € pour un pilote si on arrive à montrer que les dossiers sont complets plus
vite. Ce n'est pas un engagement ferme.

## 5. Strategy proposal

**Calm**

Calm writes the proposed APOP strategy shown in snapshot
`03-strategy-proposed`, marks it `proposed`, and asks whether the founder wants
to agree, challenge, or change it. No action plan or asset exists yet.

## 6. Explicit agreement

**Founder**

Oui, c'est la bonne stratégie. Construisons le plan autour de ça.

## 7. Plan proposal

**Calm**

Calm marks the unchanged strategy `agreed`, creates the proposed Now / Next /
Later plan shown in snapshot `04a-plan-proposed`, and asks whether the founder
wants to start with these actions. No asset exists yet.

## 8. Plan agreement and asset brief

**Founder**

Oui. On démarre avec ces actions.

**Calm**

Calm marks the unchanged plan `agreed`. It creates no asset yet. For `ACT-003`,
it proposes this short conversational brief:

- Deliverable: one finished founder-to-owner outreach message.
- Purpose: test the “complete file, then invoice” positioning.
- Audience: owners of fire-safety maintenance companies with 5–30 field
  technicians.
- Scope: one French message saved under `.calm/assets/`; no landing page,
  directory, blog, or newsletter.

Calm asks the founder whether to create that asset from this brief.

## 9. Explicit asset approval and creation

**Founder**

Oui, crée ce message d'outreach avec ce brief.

**Calm**

Calm creates only the approved finished outreach message required by
`ACT-003`, “Tester le positionnement auprès de 20 entreprises ciblées”. It
does not return a prompt and does not create a directory, blog, newsletter, or
landing page that the founder did not approve.

## 10. First status view

**Founder**

Montre-moi où on en est.

**Calm**

The local overview is regenerated from the agreed strategy, action tracker,
asset index, and latest evidence. No HTML dashboard is created by default.

## 11. Weekly check-in

**Calm**

La semaine dernière, nous avions convenu de :

1. mesurer le délai actuel sur les dossiers des deux pilotes ;
2. interroger dix dirigeants correspondant à l'ICP ;
3. tester le message auprès de vingt entreprises ciblées.

Dis-moi ce qui s'est passé. Donne-moi les chiffres, les conversations, les
réussites, les échecs, les surprises ou tout autre élément important. Écris
naturellement.

**Founder**

J'ai envoyé 12 messages. Quatre personnes ont répondu et j'ai eu deux appels.
Les deux dirigeants ont reconnu qu'ils attendaient parfois des documents avant
de facturer, mais aucun n'a accepté de pilote payant pour l'instant.

Chez un de mes pilotes, un dossier qui prend habituellement environ trois jours
a été complet le jour même et ils ont envoyé la facture le jour même. Ils
étaient contents, mais c'est un seul dossier. Je n'ai pas encore assez de
données sur les autres interventions.

## 12. Weekly response

**Calm**

Calm records the week shown in snapshot `06-weekly`, using the fixed five-section
weekly format. The result supports continuing the test, but one successful
dossier and two calls do not justify a change to Alignment, Positioning, Offer,
or Promotion. The strategy file stays unchanged and `Strategy changes` says
`None`.

## 13. Optional HTML branch

**Founder**

Crée-moi aussi une vue HTML locale.

**Calm**

`calm status --html` creates `dashboard.html` from the same local sources. It
does not start a server, create an account, or connect to an external system.
