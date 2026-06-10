**Repository for the CEBRA analysis in "Asymmetric social representations in the prefrontal cortex for 
cooperative behavior."**

**System requirements** 

This CEBRA analysis has been tested with two computing set ups: (1) with an nvidia A6000 GPU with nvidia driver version 535.129.03, CUDA version 12.2, and OS Ubuntu 20.04.6 LTS; (2) with nvidia 4070Ti with NVIDIA driver version 560.94, CUDA version 12.2, and OS windows 11.

**Installation instructions** 

1) Follow the CEBRA installation guide here: https://cebra.ai/docs/installation.html.
2) Download any necessary packages you run into that you do not have when trying to load the notebooks or run scripts.
3) If data is provided to you, you can download that folder named `data/` with the subdirectories below and place this `data/` folder at the root of the directory.

- demo_tmp_save/ is temporary storage for training models with CEBRA.

- gridsearch_results/ contains CEBRA embeddings and time-locked behavior data that are used to generate the paper figures, and includes all 7 animals used in this analysis with the best parameter set found by gridsearching.

- neural/ contains, for now, just the neural activity and time-locked behavior of one mouse, the mouse which was used to generate the paper figures, so that a demo can make use of this data.

Installation usually takes a few minutes with strong internet connection. The `data/` folder is around 10 GB, so it may take a few minutes or more to download, depending on internet connection strength.

**How to recreate the figures in the paper**

If you want to recreate the figures in the paper, `notebooks/figure_creating_demos/recreate_paper_figures_3D_scatterplot_silhouettes_matplotlib.ipynb` recreates the CEBRA plot from the paper provided that you download the dataset which has the gridsearch result that was used in the paper for animals YC069 to YC076. The expected outputs are the same figures seen in the paper. Run time is a few minutes with many parallel cores, but can take hours if you only have a few cores available for parallel processing.

**How do I train a CEBRA model on a sample dataset and create embeddings on a validation set with actual behavior and controls like in the paper?**

If you want to train the model and create embeddings on the same animal that is used in the paper figure, see `notebooks/cebra_training_and_get_embeddings_demos/train_and_get_embeddings.ipynb`. The output will be a new folder in the `data/gridsearch_results/` folder. Run time is a few minutes.

If you want to create 3D embeddings plots and silhouette score visualizations for the model fit from `train_and_get_embeddings.ipynb`, see `notebooks/figure_creating_demos/3D_scatterplot_new_embedding_fit.ipynb`. The output will be 4 plots of 3D embeddings like in the paper plus silhouette score plots with just one data point per condition. Run time is a few minutes with many parallel cores, but can take hours if you only have a few cores available for parallel processing.

**Gridsearch code and helper functions**

If you want to see the code we used for gridsearching, `Library/python/train_and_get_embeddings_gridsearch/gridsearch.py` contains code to do a gridseach to find good parameters for the CEBRA model, although the code present here searches only a small subset of the parameter set space from a larger parameter space search that we conducted. Run time is dependent on the for loop that controls the gridsearch length and will populate the `data/gridsearch_results/` folder.

`Library/python/cebra_analysis_helpers/` contains helper functions to train the models, get embeddings, make plots, get silhouette scores, etc..
