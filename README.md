
Décodeur DTMF par l'algorithme de Goertzel

Décodage des tonalités de touches téléphoniques en MATLAB, sans toolbox. Le projet comprend la génération des signaux, l'algorithme de Goertzel codé à la main et vectorisé, les règles de décision normalisées, la logique anti-rebond, ainsi qu'une évaluation de robustesse par la méthode de Monte-Carlo.

Contexte

Chaque touche d'un clavier téléphonique émet la somme de deux sinusoïdes, combinant une fréquence de ligne et une fréquence de colonne. Pour décoder le signal, il suffit de mesurer l'énergie aux fréquences spécifiques définies par la norme. Calculer une transformée de Fourier complète sur tout le spectre s'avère inutile. Ce projet met en œuvre l'algorithme de Goertzel, particulièrement adapté à ce cas d'usage, car il permet d'évaluer la puissance spectrale sur des fréquences cibles uniques au moyen d'un filtre récurrent du second ordre à coefficient réel.


Méthode

1. Découpage : Partitionnement du signal en blocs temporels de taille fixe avec un recouvrement partiel. La dimension des blocs est choisie pour aligner précisément les fréquences d'analyse avec la grille théorique du standard téléphonique.
2. Filtrage : Application de l'algorithme de Goertzel sur les fréquences fondamentales et leurs deuxièmes harmoniques. L'implémentation est entièrement vectorisée pour traiter simultanément l'ensemble des fréquences et des blocs, limitant l'usage des boucles MATLAB.
3. Décision : Analyse de chaque bloc à l'aide de critères stricts inspirés des recommandations internationales. Les filtres vérifient le taux d'énergie totale du bloc, l'émergence des pics par rapport au bruit, l'écart de niveau entre le groupe bas et le groupe haut, ainsi que le niveau des harmoniques pour écarter les faux signaux comme la voix.
4. Anti-rebond : Validation temporelle exigeant la détection continue de blocs identiques pour confirmer l'appui sur une touche et éviter les déclenchements multiples.

Résultats

Les simulations valident l'exactitude de l'algorithme maison par rapport aux fonctions de référence. L'approche par le filtre de Goertzel réduit significativement le nombre d'opérations et le coût de calcul par rapport à une transformée rapide classique.
Les tests statistiques de robustesse mettent en évidence une excellente immunité face au bruit gaussien additif. Lorsque le niveau de bruit est faible ou modéré, le système assure un décodage parfait. Lorsque le signal est fortement dégradé par le bruit ou que la durée des tonalités devient critique, le décodeur privilégie la non-détection sécurisée plutôt que la génération de touches erronées, ce qui correspond au comportement attendu d'un 