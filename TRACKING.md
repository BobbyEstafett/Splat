# Tracking & Motion : la caméra « fenêtre » (fork OVVO)

Ce fork de Gausseous ajoute une section **Tracking** dans le rail. La position
du spectateur, suivie par webcam ou par le gyroscope d'un téléphone, déplace le
point de vue : l'écran se comporte comme une fenêtre ouverte sur la scène.
Toutes les fonctions de Gausseous restent en place : caméra Manual / Keyframes /
Orbit, pivot, Correct, masks, DoF, film, audio, presets et export.

## Démarrage rapide

```
python3 -m http.server
```

1. Ouvrir <http://localhost:8000/>, puis cliquer sur **Load test asset** ou déposer un splat.
2. Dans **Tracking**, choisir la source **Webcam — head**, puis **Start**. Le navigateur demande l'accès à la caméra.
3. Se placer à la position de visionnage normale et appuyer sur **Calibrate** (touche `C`).
4. Bouger la tête : la scène se révèle derrière l'écran.

La webcam exige **https ou localhost**. GitHub Pages convient ; une IP locale
en http ne fonctionne pas.

## Sources

| Source | Usage | Notes |
|---|---|---|
| Webcam — head | Écran fixe d'installation | MediaPipe Face Landmarker, environ 30 fps. Le point suivi est le milieu des deux yeux et la distance est estimée par l'écart interpupillaire. |
| Gyroscope — phone | Mobile | Sur iOS, la permission doit être accordée au tap : il faut appuyer sur **Start** (pas de démarrage automatique). |
| Video file — head | Répétition sans être devant l'écran | Même pipeline que la webcam, alimenté par une vidéo de tête pré-enregistrée qui tourne en boucle (bouton **Choose video…**). Si la vidéo est en miroir, cocher *Invert X*. |
| Mouse — test | Mise au point sans caméra | La position du pointeur sur le viewport tient lieu de position de tête. |
| Recorded take | Relecture / export | Rejoue une prise enregistrée, calée sur la timeline. |

## Modes

- **Window — off-axis** (par défaut) : vraie projection asymétrique (perspective
  généralisée de Kooima). La « vitre » est un rectangle fixe placé devant la
  caméra. Quand l'œil bouge, l'orientation de la caméra ne change pas : seul le
  frustum se déforme. C'est ce qui donne l'illusion de fenêtre plutôt que
  celle d'une caméra qui tourne.
- **Orbit — parallax** : la tête fait orbiter la caméra autour du pivot. L'effet
  est plus spectaculaire mais moins « physique ».

## Réglages

| Réglage | Rôle |
|---|---|
| Amount | Amplification du déplacement latéral. 1 donne une fenêtre réaliste (si la hauteur d'écran est juste) ; au-delà, l'effet est exagéré, ce qui est souvent plus lisible en installation. |
| Depth (lean in) | Effet de l'avancée et du recul du spectateur. |
| Window plane | Position de la vitre, en fraction de la distance caméra → pivot. Sous 1, le sujet est derrière la vitre ; à 1, le pivot reste fixe à l'écran ; au-dessus de 1, le sujet traverse la vitre. |
| Orbit range | Angle maximal en mode Orbit. |
| Smoothing | Fréquence de coupure du filtre One Euro. Plus bas, l'image est plus stable mais plus lente à suivre ; plus haut, elle est plus réactive. |
| Screen height (cm) | Hauteur physique de l'image affichée. Elle sert à convertir les millimètres de déplacement de la tête en unités d'écran. |
| Webcam FOV | Champ horizontal de la webcam, utilisé pour estimer la distance. |
| Invert X / Y | Inverse les axes, par exemple pour une caméra montée à l'envers ou un usage en miroir. |

Si le spectateur sort du champ, l'image reste figée 0,4 s, puis revient
doucement au centre.

## Tracking et timeline

Le tracking s'ajoute **en offset** au-dessus de la caméra existante. Il ne
remplace ni la caméra Manual, ni les keyframes, ni l'Orbit. On peut donc animer
un travelling en keyframes et laisser le spectateur regarder « autour » pendant
le mouvement. Le décalage est appliqué juste avant le rendu puis annulé
juste après : OrbitControls, les keyframes, le « off curve » et les presets
voient toujours la caméra d'origine.

Le tracking est suspendu en mode **Correct** et pendant le **Pick**
(pivot / focus), parce que ces outils ont besoin de la caméra non décalée.

## Export vidéo

Le tracking live **n'est jamais exporté**, car il ne serait pas reproductible.
Pour exporter un mouvement de tête :

1. Démarrer une source live, par exemple la webcam.
2. Cliquer sur **Record take**. La timeline repart de 0 et le mouvement est enregistré sur un tour complet.
3. **Render** : la prise est appliquée image par image (option *Apply take to video export*).

La prise est enregistrée dans le preset JSON. La source et l'état on/off ne le
sont pas, parce qu'ils dépendent de la machine.

## Motion : une vidéo pilote la caméra

La section **Motion** transfère le mouvement d'une caméra filmée vers la caméra
virtuelle. Il y a deux voies.

### 1. Depuis une vidéo — analyse 2D (dans le navigateur)

**Load video…** analyse n'importe quel clip (MP4 H.264, WebM ; le MOV ProRes
n'est pas lu par les navigateurs). Le logiciel suit des points d'une image à
l'autre, puis en déduit le **panoramique**, le **tilt**, le **roulis** et
l'**avancée / recul** (zoom apparent). La courbe s'affiche sous le bouton. Le
mouvement est appliqué **en offset** par-dessus le mode caméra courant, et il
part de la caméra telle que tu l'as cadrée.

| Réglage | Rôle |
|---|---|
| In place / Around pivot | *In place* : la caméra tourne sur elle-même, comme la vraie. *Around pivot* : la rotation devient une orbite autour du pivot, et le sujet reste dans le cadre. |
| Full / Smooth only / Shake only | Tout le mouvement, seulement sa composante lente (stabilisée), ou seulement le tremblé, pour donner une sensation de caméra à l'épaule à n'importe quel plan. |
| Rotation / Roll / Push gain | Amplitude de chaque composante. Une valeur négative inverse le sens. |
| Clean | Lissage anti-bruit du tracking, en images. |
| Shake split | Fréquence de séparation entre lent et tremblé, en images. |
| Clip FOV | Champ horizontal de la caméra qui a filmé. Il convertit les pixels en angles : un 24 mm plein format fait environ 74°, un smartphone en grand-angle environ 65-75°. |
| Analysis rate | Nombre d'images analysées par seconde de vidéo. |

**Timeline = clip length** cale la durée de la timeline sur celle du clip, pour
que le mouvement passe à sa vitesse réelle. Sinon, il est étiré sur la
timeline. Le mouvement est déterministe : il passe tel quel à l'export vidéo,
et les courbes sont enregistrées dans le preset.

Limite : c'est une estimation 2D, pas une reconstruction. Un travelling latéral
est lu comme un panoramique. Pour un mouvement exact, il faut passer par la voie 3D.

L'analyse prend typiquement quelques fois la durée du clip (selon la machine), et la vue 3D se fige
pendant le calcul. Sur un clip long, 15 images par seconde suffisent souvent.

### 2. Depuis une trajectoire caméra — import 3D (exact)

Le camera tracking se fait dans un outil dédié, puis on importe le résultat
avec **Load track…** :

| Format | Vient de |
|---|---|
| `transforms.json` | Nerfstudio, Instant-NGP et les pipelines de splats qui suivent ce format |
| `images.txt` (+ `cameras.txt`, sélectionner les deux) | COLMAP, c'est-à-dire souvent la trajectoire qui a servi à entraîner le splat |
| `.gltf` / `.glb` avec une caméra animée | Blender (Motion Tracking → Solve, puis export glTF avec l'animation), Cinema 4D, Houdini… |
| `.chan` | Nuke (et After Effects via un script d'export) : `frame tx ty tz rx ry rz [vfov]`, ordre ZXY |

La trajectoire devient le mode caméra **Path**, à côté de Manual / Keyframes /
Orbit. Position, orientation (roulis compris) et focale sont rejouées.

- **Relative to current camera** (par défaut) : la trajectoire démarre là où
  est la caméra au moment de l'import, et seul le *mouvement* est transféré.
  **Scale** règle son ampleur (à ×1, le mouvement couvre environ un rayon de
  scène). Pour repartir d'ailleurs : cadrer en mode Manual, puis **Re-anchor here**.
- **Splat space (same capture)** : si la vidéo trackée est celle qui a servi à
  capturer le splat, ses poses sont déjà dans le repère du splat, et la prise de
  vue d'origine est rejouée exactement. Le *Transform* de Gausseous (Correct)
  est appliqué automatiquement. Si les axes ne collent pas, utiliser
  **World** : Nerfstudio → COLMAP (annule l'`applied_transform` du JSON),
  Z-up → Y-up, Y-up → Z-up.
- **Track fps** : sert à calculer la durée réelle des formats « image par
  image » (COLMAP, transforms.json, .chan). Les numéros d'image présents dans
  les noms de fichiers (`frame_00042.png`) sont respectés, donc les images non
  recalées par COLMAP ne décalent pas le timing.
- **Bake to keyframes** : convertit la trajectoire en N keyframes caméra,
  éditables avec les outils habituels. Le roulis est perdu, car un keyframe
  ne stocke que la position et la cible.

Le head tracking et le mouvement 2D s'ajoutent par-dessus le mode Path.
Ordre d'application : orientation exacte du Path, puis mouvement 2D, puis tête.

## Copier / coller des keyframes

**Paramètres (la lane du bas).**
- Sélection : clic sur un key pour le sélectionner, `Shift`-clic pour en
  ajouter ou en retirer, `Shift`-glisser dans le vide pour une sélection au
  rectangle, `Ctrl/Cmd+A` pour tout sélectionner. Glisser un key sélectionné
  déplace toute la sélection.
- `Ctrl/Cmd+C` copie la sélection (ou tous les keys du paramètre si rien n'est
  sélectionné), `Ctrl/Cmd+X` coupe, `Suppr` efface.
- `Ctrl/Cmd+V` colle **à la tête de lecture**, sur le paramètre affiché dans la
  lane. On peut coller sur un *autre* paramètre : la forme est conservée et
  remise à l'échelle de sa plage (par exemple copier une courbe de Noise sur la
  Saturation).
- Les mêmes actions existent en boutons dans la lane : **Copy** / **Paste**.

**Caméra (la rangée de ticks au-dessus de la lane, en mode Keyframes).**
- `Shift`-clic sur un tick pour le sélectionner, puis copier / coller au
  clavier après avoir cliqué dans la rangée, ou avec les boutons **Copy keys** /
  **Paste keys** de la section Camera.
- Coller place les keys à la tête de lecture ; les keys qui dépasseraient la
  fin de la timeline sont ignorés.

Le presse-papier survit à un rechargement et passe d'un onglet à l'autre : on
peut copier un mouvement d'un preset et le coller dans un autre.

## Courbes de vitesse entre keyframes (section Camera → *Easing between keyframes*)

Chaque intervalle entre deux keyframes (un *segment*) peut avoir sa propre
courbe, pour la caméra comme pour n'importe quel paramètre animé.

**Choisir le segment.** L'éditeur montre le segment sous la tête de lecture :
- de la **caméra** quand on a cliqué en dernier dans la rangée de ticks caméra
  (un clic entre deux ticks place la tête de lecture dans ce segment) ;
- du **paramètre affiché dans la lane** quand on a cliqué en dernier dans la
  lane ou sur le nom d'un paramètre.

◀ / ▶ passent au segment précédent / suivant.

**Deux vues de la même courbe :**
- **Speed** (comme le graphe de vitesse d'After Effects). La hauteur est la
  vitesse ; ×1 est la vitesse moyenne du segment (ce que donnerait un mouvement
  linéaire). Chaque poignée règle la vitesse **au départ** et **à l'arrivée**
  du keyframe (haut / bas) et son **influence** (gauche / droite : sur quelle
  part du segment cette vitesse agit).
- **Value** : la courbe de bézier classique, progression entre les deux keys
  au cours du temps. Monter une poignée au-dessus du cadre fait un dépassement
  (overshoot), la descendre en dessous fait une anticipation.

**Raccourcis :**
- **Curve…** propose des courbes toutes faites : linéaire, smooth, ease in,
  ease out, ease in+out fort, départ rapide, arrivée rapide, overshoot,
  anticipation, ralenti puis accélération.
- **Default** rend au segment le comportement d'origine (réglage *Ease* pour la
  caméra, Smooth / Linear pour les paramètres).
- **Copy curve / Paste curve** : copie la courbe d'un segment et la colle sur
  un autre. Si des keys sont sélectionnés sur la piste (Shift-clic), elle est
  collée sur le segment de chacun d'eux.
- **Apply to all** : met la même courbe sur tous les segments de la piste.

Les courbes voyagent avec les keyframes : copier-coller de keys, presets,
export vidéo.

## Plein écran sans interface (Kiosk)

La touche **`K`** (ou le bouton **Kiosk** de la section Tracking) passe en
plein écran et masque toute l'interface : panneau, timeline, compteurs, aperçu
webcam. Le curseur disparaît après 2 s sans mouvement. `K` ou `Échap` font
revenir l'interface. La touche `H` masque seulement l'interface, sans plein écran.

Le tracking, le MIDI, la lecture et l'audio continuent de fonctionner en Kiosk.

## Contrôleur MIDI (Akai LPD8, LPD8 Wireless, etc.)

La section **MIDI** relie n'importe quel potard ou pad à n'importe quel réglage
de l'interface, par apprentissage :

1. **Enable MIDI** (Chrome ou Edge). Le contrôleur apparaît sous les boutons.
2. **Learn**, puis cliquer sur un réglage à l'écran (slider, bouton, case, menu).
3. Tourner un potard ou frapper un pad : la liaison est créée. Recommencer pour
   le réglage suivant, puis recliquer sur **Learn** pour terminer.

| Sur le contrôleur | Sur un slider | Sur un bouton | Sur une case | Sur un menu |
|---|---|---|---|---|
| Potard (CC) | balaie toute la plage | déclenche au passage du milieu | coche / décoche | choisit l'entrée |
| Pad (note ou program change) | coup momentané : vélocité = intensité, relâché = retour | appuie | bascule | entrée suivante |

- **inv** inverse le sens d'une liaison, **×** la supprime.
- **Smoothing** lisse les potards (un potard MIDI n'a que 127 crans).
- Les liaisons sont mémorisées sur la machine, voyagent dans les presets, et
  s'exportent / s'importent en fichier.
- Un potard pilote le slider lui-même : si le paramètre est armé en keyframes,
  le mouvement s'enregistre comme à la souris.

### Connexion du LPD8 Wireless

- **En USB** : rien à faire, il apparaît dès **Enable MIDI**.
- **En Bluetooth sur macOS** : l'appairer dans *Configuration audio et MIDI →
  Fenêtre → Afficher le studio MIDI → Bluetooth*. Il apparaît ensuite comme un
  port MIDI normal.
- **En Bluetooth sur Windows, ChromeOS ou Android** : utiliser le bouton
  **Bluetooth…**, qui se connecte directement depuis le navigateur (BLE-MIDI),
  sans pilote. Il se reconnecte seul si le contrôleur s'est mis en veille.

Les pads du LPD8 fonctionnent dans ses trois modes (PAD, CC, PROG CHNG).

Un pad MIDI ne peut pas déclencher le vrai plein écran : le navigateur exige
une touche ou un clic. Lié au bouton Kiosk, il masque et réaffiche l'interface ;
lancer le plein écran une fois avec `K` ou `F11`.

## Clavier

| Touche | Action |
|---|---|
| `T` | démarrer / arrêter le tracking |
| `C` | calibrer (la position actuelle devient le centre) |
| `K` | Kiosk : plein écran sans interface |
| `H` | masquer / afficher le rail |

## Installation sans surveillance

Tous les paramètres d'URL sont optionnels :

```
index.html?splat=scenes/hall.ply&preset=presets/hall.json&track=webcam&mode=window&play&kiosk
```

- `splat` / `preset` : chargés au démarrage (URL relatives au serveur).
- `track=webcam|mouse|take` : démarre la source. Le gyroscope est exclu, car iOS impose un tap.
- `play` : lance la timeline. `kiosk` : masque toute l'interface.
- Pour un vrai plein écran sans clic, lancer le navigateur en mode kiosque,
  par exemple `chrome --kiosk --use-fake-ui-for-media-stream "http://localhost:8000/?…"`.
  Le second flag accorde la caméra automatiquement ; à réserver à une machine dédiée.

### Hors ligne

```
tools/vendor-mediapipe.sh      # télécharge le runtime wasm et le modèle dans vendor/mediapipe
```

Ouvrir ensuite `index.html?local`. Three.js et Spark viennent toujours de leur CDN
(voir l'importmap en tête de `index.html`). Pour une machine totalement hors
ligne, il faut aussi les copier en local et modifier les URLs de l'importmap.

## Limites connues

- La distance est estimée par l'écart entre les yeux. Une tête très tournée
  paraît plus lointaine qu'elle ne l'est.
- Un seul spectateur est suivi (le premier visage détecté).
- Motion 2D : un plan avec beaucoup de sujets en mouvement (foule, eau) ou un
  flou de bougé fort fausse l'estimation. Les images non suivies sont tenues
  immobiles et comptées dans l'info.
- L'export vidéo exige toujours Chrome ou Edge (WebCodecs), comme l'original.
- Le modèle MediaPipe (environ 3,6 Mo) et le runtime wasm (environ 12 Mo) se
  chargent au premier Start. Le chargement prend quelques secondes en ligne.
