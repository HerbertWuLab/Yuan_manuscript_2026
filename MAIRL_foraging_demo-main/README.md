
# Multi-Agent Inverse Reinforcement Learning

Algorithm details:  
Chen, Y., Radulescu, A. & Wu, Z. (2024) Unveiling the latent dynamics in social cognition with multi-agent inverse reinforcement learning*  
[📄 View paper](https://www.biorxiv.org/content/10.1101/2024.10.09.617461v1.abstract)

---

## 📦 Environment Setup

To set up the environment:

```bash
conda env create -f environment.yml
```
This will probably take 5–10 minutes on a typical Linux machine.

---

## 🚀 Run the Inference Algorithm

Make the script executable and run it:

```bash
chmod +x run_demo.sh
./run_demo.sh
```

Preliminary results will be available in:

```
recovered_parameters/coop_foraging/experiment_coop_foraging/
```

---

## 📊 Plot Manuscript Figure 6

To generate a figure:

```bash
python make_figures_coop_foraging.py --figure_idx 1
```

### 📈 Figure Index Guide

```
# Figure index purposes:
# 1     : Model selection (main figure)
# 1.1   : Generate LL gain and p-value tables for imagined pairs
# 1.11  : Generate LL gain and p-value tables for c-table (behavioral data)
# 1.2   : Model selection, plot F/L on same panel
# 1.21  : Plot number of pairs significant during model selection
# 1.3   : Model selection, multiple pairs (LL gain)
# 1.31  : Model selection, multiple pairs (LL per decision)
# 2     : Plotting fitting maps (single animal)
# 2.1   : Plot maps for different conditions (single animal)
# 2.11  : Plot maps for mismatch conditions (across animals)
# 2.2   : Plot map for HD fitting (single animal)
# 3     : Plotting maps across multiple animals (main figure)
# 3.1   : Plot map for HD fitting: multiple pairs
# 4     : LL gain vs. decoding accuracy (main figure)
# 5     : Neural activity vs. Value representation (example p-value calculation)
# 5.1   : Population neural decoding: -log(pvalue) vs. R2
# 5.2   : Trials stats for daily sessions
# 6     : Simulate trajectories and calculate reward zone chosen probability
# 6.1   : Plot simulation results (main figure)
```

---

## Repo structure 
```
.
├── run_demo.sh                       # Shell script to run demo inference
├── run_coop_foraging.sh              # Shell script to run all dataset involved in the manuscript 
├── main_irl_foraging.py 	          # Main program
├── make_figures_coop_foraging.py     # Figure generation script
├── environment.yml                   # Conda environment file
├── recovered_parameters/             # Output from inference runs
├── data/                             # Raw data, processed data and simple visualizations
└── README.md

```