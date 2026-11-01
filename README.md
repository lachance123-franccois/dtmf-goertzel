
Décodeur DTMF par l'Algorithme de Goertzel

Décodage de tonalités téléphoniques (DTMF) en MATLAB sans aucune toolbox. Génération de signaux avec préallocation, algorithme de Goertzel vectorisé, critères de décision normalisés (twist, harmoniques), logique anti-rebond et évaluation statistique par simulations de Monte-Carlo.

Principes et Méthode

Chaque touche d'un clavier émet la somme de deux sinusoïdes : une fréquence de ligne (basse) et une fréquence de colonne (haute). Isoler ces 8 composantes avec une FFT complète serait inefficace. Ce projet utilise l'algorithme de Goertzel, qui évalue un filtre IIR récurrent du second ordre pour chaque fréquence cible.

	1209 Hz	1336 Hz	1477 Hz	1633 Hz
697 Hz	1	2	3	A
770 Hz	4	5	6	B
852 Hz	7	8	9	C
941 Hz	*	0	#	D


Étapes de traitement :

1. Fenêtrage : Découpage du signal en blocs de N = 205 échantillons à 8 kHz (≈ 25,6 ms), avec un recouvrement de 50%. Cette valeur de N minimise l'écart entre les bins de la TFD et les fréquences théoriques du standard.
2. Calcul spectral vectorisé : Évaluation de la puissance |X(ω)|² sur les 8 fondamentales et leurs secondes harmoniques :
\(s_{0}[n]=x[n]+2\cos (\omega )s_{1}[n-1]-s_{2}[n-2]\)
\(|{}X(\omega )|{}^{2}=s_{1}[N-1]^{2}+s_{2}[N-2]^{2}-2\cos (\omega )s_{1}[N-1]s_{2}[N-2]\)
L'implémentation est vectorisée en fréquences et en blocs, limitant la boucle MATLAB à la seule dimension temporelle N.
3. Bloc de décision (ITU-T Q.24) : Validation de l'énergie des deux tonalités dominantes (> 40%), rejet par facteur de crête spectrale (> 6 dB), contrôle du « twist » (< 8 dB) et élimination des harmoniques (< 20%) pour immuniser le système contre la voix ou la musique.
4. Persistance temporelle : Filtre anti-rebond imposant une détection stable sur au moins 2 blocs consécutifs avant validation de la touche.

Résultats de Simulation

Les analyses statistiques (300 tirages par point de SNR) mettent en évidence les performances réelles du récepteur :

Scénario de test	Taux de bonne détection	Observation
Tonalité de 80 ms, SNR ≥ 0 dB	100 %	Décodage parfait sans aucune fausse touche.
Tonalité de 40 ms, SNR = 0 dB	≈ 98 %	Transition fluide à la limite des normes télécoms.
SNR = -2 dB (80 ms / 40 ms)	67 % / 31 %	Les échecs sont des non-détections (rejet sécurisé).
SNR = -2 dB, durée ≤ 20 ms	≈ 12 %	Chute nette sous la fenêtre critique de l'anti-rebond.


Avantages computationnels

• Précision machine : L'erreur relative maximale mesurée entre l'algorithme maison et la fonction native fft() est de l'ordre de 1,72 ⋅ 10⁻¹⁴.
• Complexité réduite : Goertzel requiert 8 × (205 + 3) = 1664 multiplications réelles par bloc, contre ≈ 4096 pour une FFT Radix-2 sur 256 points.

Structure du Code

text
main.m                  Script de démonstration (calculs, graphiques et animation live)
src/dtmf_decode.m       Décodeur de production allégé (décision et anti-rebond)
src/dtmf_generate.m     Générateur de signaux optimisé (préallocation mémoire)
src/goertzel_power.m    Algorithme de Goertzel vectorisé
src/dtmf_eval_snr.m     Évaluation de robustesse par méthode de Monte-Carlo
src/dtmf_tables.m       Fréquences de référence normalisées
src/stft_mag.m          Calcul de spectrogramme matriciel autonome
src/save_fig.m          Utilitaire adaptatif d'exportation d'images
Utilisez le code avec précaution.

Lancement

Exécutez le script principal depuis la console MATLAB :
matlab
>> main
Utilisez le code avec précaution.
• Configuration requise : MATLAB R2021a ou supérieur (sans aucune toolbox).
• Test personnalisé : Déposez un fichier audio dans data/mon_enregistrement.wav pour tester le décodeur sur vos propres signaux ou captures réelles.