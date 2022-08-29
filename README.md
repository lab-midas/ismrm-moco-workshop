# Hands-on motion estimation and correction
**ISMRM Workshop on Motion Detection and Correction 2022**<br/>
*Gastao Cruz and Thomas Kuestner*<br/>

In this hands-on of the [ISMRM Workshop on Motion Detection and Correction 2022](https://www.ismrm.org/workshops/2022/Motion/), we aim to convey the principles of motion artifacts, their appearance in the MR image, means of estimating motion (conventional and deep learning) and correcting for the induced motion artifacts.

Supporting codebase and data for motion correction are supplied in this repository. Python codes are provided to execute and experiment with different motion correction strategies inside a Jupyter notebook-

## Getting started
Hands-on tutorial:
- Exercise: [Jupyter Notebook](https://github.com/lab-midas/ismrm-moco-workshop/blob/master/HandsOn_ISMRM_MoCo_Workshop.ipynb) or <a href="https://colab.research.google.com/github/lab-midas/ismrm-moco-workshop/blob/master/HandsOn_ISMRM_MoCo_Workshop.ipynb" target="_parent"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"></a>
- Solutions: [Jupyter Notebook](https://github.com/lab-midas/ismrm-moco-workshop/blob/master/HandsOn_ISMRM_MoCo_Workshop_solution.ipynb) or <a href="https://colab.research.google.com/github/lab-midas/ismrm-moco-workshop/blob/master/HandsOn_ISMRM_MoCo_Workshop_solution.ipynb" target="_parent"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"></a>

## Syllabus
### Target audience
MR scientists interested in advanced motion estimation and correction techniques. After completing this workshop, the participants should be able to:
-	Understand how motion affects MR acquisition and reconstruction
-	Understand existing approaches to deal with motion
-	Understand and perform motion estimation including deep learning-based solutions
-	Understand and perform motion corrected reconstructions

### Outline
We will study the problem of motion in MR, starting with the various sources of motion in MR and how they impact the acquisition and reconstruction processes. Various types of motion models and physiological motion challenges will be considered, along with the typical artefacts encountered and general prospective and retrospective approaches to deal with motion<sup>1</sup>. The mechanisms behind motion artefacts will be described, recognizing motion artefacts as superposition of aliased images in different motion states. The impact of motion artifacts on Cartesian and non-Cartesian acquisitions will be illustrated as well as means to correct for it.

The first component of this workshop will be talks covering the fundamentals of motion in MR, with a strong focus on retrospective motion correction strategies<sup>2</sup>, including deep learning-based solutions. The generalized forward model for an MR acquisition considering motion will be introduced<sup>3</sup>. This model will be used to: 1) characterize the profile of the aliasing introduced due to motion and understand how the relationship between the geometry of the motion and the geometry of the sampling trajectory determines these artefacts; 2) provide a reconstruction model to correct for generalized motion occurring during the MR acquisition. The talks will further discuss practical and general approaches to estimate and correct for motion, including techniques like triggering and gating<sup>4,5</sup>, motion binning<sup>6</sup>, image registration<sup>7-9</sup>, k-space motion correction<sup>10</sup>, deep learning-based image registration<sup>11,12</sup> and motion corrected reconstruction<sup>3,9</sup>.

The second component of this workshop will include a hands-on tutorial with code examples focusing on retrospective motion correction which covers three aspects: motion artifact appearance, motion estimation via image registration and motion corrected reconstructions. First, we will analyse different types of motion artefacts, evaluating their behaviour in the context of different motion model geometries (e.g. translation, rigid, affine, etc) and different trajectories (e.g. Cartesian, radial, etc). Second, we will experiment with image registration tools for motion estimation and investigate their performance in various scenarios. Third, we will implement a motion corrected reconstruction and study the properties of that model in the presence of noise, undersampling or model errors. We will apply all these approaches to real in-vivo cases.

After completing this workshop, the attendees should have a better understanding of how motion affects MR acquisitions, the type of artefacts it can introduce, existing strategies for dealing with motion, and get practical experience in retrospective motion estimation and correction. 

### Citation
**If you use this code in a publication please consider referencing the following papers (as relevant):** 

[a] Küstner T, Pan J, Gilliam C, Qi H, Cruz G, Hammernik K, Blu T, Rueckert D, Botnar R, Prieto C, Gatidis S. Self-supervised motion-corrected image reconstruction network for 4D magnetic resonance imaging of the body trunk. APSIPA Transactions on Signal and Information Processing. 2022 Feb 21;11(1):e12.

b. Küstner T, Pan J, Qi H, Cruz G, Gilliam C, Blu T, Yang B, Gatidis S, Botnar R, Prieto C. LAPNet: Non-rigid Registration derived in k-space for Magnetic Resonance Imaging. IEEE Transactions on Medical Imaging. 2021 Jul 9;40(12):3686-97.

c. Cruz G, Atkinson D, Henningsson M, Botnar RM, Prieto C. Highly efficient nonrigid motion‐corrected 3D whole‐heart coronary vessel wall imaging. Magnetic resonance in medicine. 2017 May;77(5):1894-908.

d. Cruz G, Atkinson D, Buerger C, Schaeffter T, Prieto C. Accelerated motion corrected three‐dimensional abdominal MRI using total variation regularized SENSE reconstruction. Magnetic resonance in medicine. 2016 Apr;75(4):1484-98.

e. Hammernik K, Küstner T. Machine Enhanced Reconstruction Learning and Interpretation Networks (MERLIN). Proceedings of the International Society for Magnetic Resonance in Medicine (ISMRM). 2022 May;1051.

### Further suggested readings
#### Motion corrected reconstructions 
Motion corrected reconstructions are based on the framework laid out by Philip Batchelor in this seminal paper:**

f. Batchelor PG, Atkinson D, Irarrazaval P, Hill DL, Hajnal J, Larkman D. Matrix description of general motion correction applied to multishot images. Magnetic Resonance in Medicine: An Official Journal of the International Society for Magnetic Resonance in Medicine. 2005 Nov;54(5):1273-80.

This paper has some very nice discussion on motion corrected reconstructions:

g. Hansen MS, Sørensen TS, Arai AE, Kellman P. Retrospective reconstruction of high temporal resolution cine images from real‐time MRI using iterative motion correction. Magnetic Resonance in Medicine. 2012 Sep;68(3):741-50.

#### Joint motion estimation / motion correction 
For interesting works addressing the problem of joint motion estimation/ motion correction check out the following:

h. Odille F, Vuissoz PA, Marie PY, Felblinger J. Generalized reconstruction by inversion of coupled systems (GRICS) applied to free‐breathing MRI. Magnetic Resonance in Medicine: An Official Journal of the International Society for Magnetic Resonance in Medicine. 2008 Jul;60(1):146-57.

i. Cordero-Grande L, Teixeira RP, Hughes EJ, Hutter J, Price AN, Hajnal JV. Sensitivity encoding for aligned multishot magnetic resonance reconstruction. IEEE Transactions on Computational Imaging. 2016 Apr 20;2(3):266-80.

j. Haskell MW, Cauley SF, Wald LL. TArgeted Motion Estimation and Reduction (TAMER): data consistency based motion mitigation for MRI using a reduced model joint optimization. IEEE transactions on medical imaging. 2018 Jan 9;37(5):1253-65.

#### Generalized motion correction
For generalized motion correction combined with dynamic contrast MR check out:

k. Cruz G, Qi H, Jaubert O, Kuestner T, Schneider T, Botnar RM, Prieto C. Generalized low‐rank nonrigid motion‐corrected reconstruction for MR fingerprinting. Magnetic Resonance in Medicine. 2022 Feb;87(2):746-63.

For a generalized non-rigid motion description:

l. Huttinga NRF, van den Berg CAT, Luijten PR, Sbrizzi A. MR-MOTUS: model-based non-rigid motion estimation for MR-guided radiotherapy using a reference image and minimal k-space data. Phys Med Biol. 2020 Jan 10;65(1):015004. 

#### Autofocusing
For an alternative way to perform elastic motion correction without Batchelor's formulation, check out some of the approaches using localized autofocus ideas:

m. Atkinson D, Hill D, Stoyle P, Summers P, Keevil S. Automatic correction of motion artifacts in magnetic resonance images using an entropy focus criterion. IEEE Trans Med Imaging 1997;16:903–910.

n. Cheng JY, Alley MT, Cunningham CH, Vasanawala SS, Pauly JM, Lustig M. Nonrigid motion correction in 3D using autofocusing withlocalized linear translations. Magnetic resonance in medicine. 2012 Dec;68(6):1785-97.

o. Loktyushin A, Nickisch H, Pohmann R, Schölkopf B. Blind retrospective motion correction of MR images. Magnetic resonance in medicine. 2013 Dec;70(6):1608-18.

#### Data-driven motion correction
For data-driven approaches which retrospectively correct for induced motion:

p. Küstner, T, Armanious, K, Yang, J, Yang, B, Schick, F, Gatidis, S. Retrospective correction of motion-affected MR images using deep learning frameworks. Magn Reson Med. 2019; 82:1527– 1540.

q. Oksuz I, Clough JR, Ruijsink B, Anton EP, Bustin A, Cruz G, Prieto C, King A, Schnabel JA. Deep learning-based detection and correction of cardiac MR motion artefacts during reconstruction for high-quality segmentation. IEEE Transactions on Medical Imaging. 2020; 39(12), 4001-4010.

r. Haskell MW, Cauley SF, Bilgic B, Hossbach J, Splitthoff DN, Pfeuffer J, Setsompop K, Wald LL. Network Accelerated Motion Estimation and Reduction (NAMER): Convolutional neural network guided retrospective motion correction using a separable motion model. Magn Reson Med. 2019 Oct;82(4):1452-1461.

#### Deep learning image registration
For deep learning image registration you may check the references provided in the Jupyter notebook and here:

b. (see above)

s. Balakrishnan G, Zhao A, Sabuncu MR, Guttag J, Dalca AV. VoxelMorph: a learning framework for deformable medical image registration. IEEE transactions on medical imaging. 2019; 38(8), 1788-1800.

t. Yang J, Küstner T, Hu P, Liò P, Qi H. End-to-End Deep Learning of Non-rigid Groupwise Registration and Reconstruction of Dynamic MRI. Front Cardiovasc Med. 2022 Apr 28;9:880186. 


### References
1. Zaitsev M, Maclaren J, Herbst M. Motion artifacts in MRI: A complex problem with many partial solutions. Journal of Magnetic Resonance Imaging. 2015 Oct;42(4):887-901.
2. Ismail TF, Strugnell W, Coletti C, Božić-Iven M, Weingärtner S, Hammernik K, Correia T, Küstner T. Cardiac MR: From Theory to Practice. Front Cardiovasc Med. 2022 Mar 3;9:826283. doi: 10.3389/fcvm.2022.826283.
3. Batchelor PG, Atkinson D, Irarrazaval P, Hill DL, Hajnal J, Larkman D. Matrix description of general motion correction applied to multishot images. Magnetic Resonance in Medicine: An Official Journal of the International Society for Magnetic Resonance in Medicine. 2005 Nov;54(5):1273-80.
4. Frost R, Hess AT, Okell TW, Chappell MA, Tisdall MD, van der Kouwe AJW, Jezzard P. Prospective motion correction and selective reacquisition using volumetric navigators for vessel-encoded arterial spin labeling dynamic angiography. Magnetic Resonance in Medicine 76(5): 1420-1430, Nov 2016
5. Gallichan, D., Marques, J.P. and Gruetter, R. (2016), Retrospective correction of involuntary microscopic head movement using highly accelerated fat image navigators (3D FatNavs) at 7T. Magn. Reson. Med., 75: 1030-1039.
6. Ehman RL, McNamara MT, Pallack M, Hricak H, Higgins CB. Magnetic resonance imaging with respiratory gating: techniques and advantages. AJR Am J Roentgenol. 1984 Dec;143(6):1175-82.
7. Rueckert D, Sonoda LI, Hayes C, Hill DL, Leach MO, Hawkes DJ. Nonrigid registration using free-form deformations: application to breast MR images. IEEE Trans Med Imaging. 1999 Aug;18(8):712-21.
8. Thirion, J-P. "Image matching as a diffusion process: an analogy with Maxwell's demons." Medical image analysis 2.3 (1998): 243-260.
9. Odille F, Vuissoz PA, Marie PY, Felblinger J. Generalized reconstruction by inversion of coupled systems (GRICS) applied to free-breathing MRI. Magn Reson Med. 2008 Jul;60(1):146-57.
10. Kustner T, Pan J, Qi H, Cruz G, Gilliam C, Blu T, Yang B, Gatidis S, Botnar R, Prieto C. LAPNet: Non-Rigid Registration Derived in k-Space for Magnetic Resonance Imaging. IEEE Trans Med Imaging. 2021 Dec;40(12):3686-3697.
11. Balakrishnan, Guha, et al. "VoxelMorph: a learning framework for deformable medical image registration." IEEE transactions on medical imaging 38.8 (2019): 1788-1800.
12. Dosovitskiy, A., Fischer, P., Ilg, E., Hausser, P., Hazirbas, C., Golkov, V., ... & Brox, T. (2015). Flownet: Learning optical flow with convolutional networks. In Proceedings of the IEEE international conference on computer vision (pp. 2758-2766).
