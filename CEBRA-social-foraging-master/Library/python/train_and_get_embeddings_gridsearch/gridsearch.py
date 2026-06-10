import sys
import matplotlib.pyplot as plt
import os
script_path = os.path.abspath("../../../Library/python/cebra_analysis_helpers")
if script_path not in sys.path:
    sys.path.append(script_path)
import cebra_analysis_helpers
import os
import random
import pickle

# global variables for videos
social_foraging_data_path =  '../../../data/neural/'
output_dir = f"../../../data/gridsearch_results/"
trial_type_to_correct_ports = {0:"north_east",
                               1:"east_south",
                               2:"south_west",
                               3:"west_north",
                               4:"north_south",
                               5:"east_west"}
zone_to_direction = {1:"north", 2:"east", 3:"south", 4:"west"}
direction_to_zone = {"north":1, "east":2, "south":3, "west":4}
direction_to_degrees = {"south":[45,135], "east": [315,45], "north": [225,315], "west": [135,225]}
mouse_id = "73"

# set up gpu
import torch
device_id = 0
print("Cuda available",torch.cuda.is_available())
print("Number of GPUs available",torch.cuda.device_count())
print("GPU name",torch.cuda.get_device_name(device_id))
torch.cuda.set_device(device_id)
if torch.cuda.is_available():
    current_device = torch.cuda.current_device()
    print(f"Using GPU: {torch.cuda.get_device_name(current_device)} (Device {current_device})")
else:
    print("CUDA is not available, running on CPU.")

# load the neural and behavioral data
skip_it_load_it = True
load_path = "../../../data/demo_tmp_save/YC073_data_each_session.pkl"
if not skip_it_load_it:
    mouse_and_date_list, neural_data_list, conditions_dict_list, indices_of_trials_each_frame_list, m_str = cebra_analysis_helpers.get_neural_and_behavioral_data_dict(social_foraging_data_path,
                                                                                                                                                                    mouse_id, 
                                                                                                                                                                    output_dir = "../../../data/demo_tmp_save/")
else:
    with open(load_path, 'rb') as f:
        neural_and_behavioral_data_dict =  pickle.load(f)
        mouse_and_date_list = neural_and_behavioral_data_dict["mouse_and_date_list"]
        neural_data_list = neural_and_behavioral_data_dict["neural_data_list"]
        conditions_dict_list = neural_and_behavioral_data_dict["conditions_dict_list"]
        indices_of_trials_each_frame_list = neural_and_behavioral_data_dict["indices_of_trials_each_frame_list"]
        m_str = f"YC0{mouse_id}"

# sample different grids of the gridsearch
for i in range(100):
    conditional = random.sample(["delta"],1)[0]
    time_offset =  random.sample([1],1)[0]
    test_size = 0.2
    output_dims = 3
    temperature_mode = random.sample(["constant"],1)[0]
    temperature = random.sample([0.1,0.2,0.5,1,1.5,2],1)[0]
    max_iter = random.sample([1000,2000,5000,10000,20000],1)[0]
    num_hidden_units = random.sample([16,32,64,128],1)[0]
    output_dims = 3
    lr = random.sample([0.0003],1)[0]
    batch_size = random.sample([256,512,1024],1)[0]
    for approach in ["noRZ_ITI+T_ByT", "noRZ_ITI+T_ByT+shift0.5"]:  
        for behavior in ["angle", "distance"]:
            cebra_analysis_helpers.run_single_grid(output_dir,mouse_and_date_list, neural_data_list, conditions_dict_list, indices_of_trials_each_frame_list,
                            m_str, batch_size,time_offset,temperature_mode,temperature,max_iter,num_hidden_units,output_dims,lr,
                            behavior,approach, conditional, test_size,  tmux_session_name = mouse_id, device_id = device_id)