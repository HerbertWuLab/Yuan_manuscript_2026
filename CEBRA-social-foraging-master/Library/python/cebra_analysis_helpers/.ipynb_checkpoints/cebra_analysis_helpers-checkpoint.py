import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import scipy.io as sio
import json
import math
import plotly.graph_objects as go
import sys
import matplotlib.pyplot as plt
import matplotlib.pyplot as plt
import pickle
import plotly.graph_objects as go
import pandas as pd
import time
from scipy.spatial.distance import cdist
from multiprocessing import Process
from multiprocessing import Manager
import numpy as np
from scipy.stats import wilcoxon
import os
from cebra import CEBRA
import cebra
script_path = os.path.abspath("../../Library/python/cebra_analysis_helpers")
if script_path not in sys.path:
    sys.path.append(script_path)
import cebra_analysis_helpers

############ figure plotting demos (silhouettes + 3D scatter) ################


def get_cluster_ranges(behavior_labels, num_clusters = 5):
    """get the ranges of each cluster for the silhouette score by quantiles 
        where the entire range is chopped up into num_clusters quantiles

    Args:
        behavior_labels (list of numeric values): the value for each frame in the session
        num_clusters (int, optional): . Defaults to 5.

    Returns:
        list of int tuples: ranges for each cluster
    """    
    # get quantiles, and get range based on quantiles of the 5 bins
    cluster_ranges = [[np.quantile(a = behavior_labels[~np.isnan(behavior_labels)].tolist(), \
        q = i / num_clusters), np.quantile(a = behavior_labels[~np.isnan(behavior_labels)].tolist(), q = (i+1) / num_clusters)] for i in range(num_clusters)]
    return cluster_ranges

def get_cluster_index(value, cluster_ranges):
    """get the cluster of a particular value
    Args:
        value (int): behavior variable value
        cluster_ranges (list of int tuples): list of cluster ranges

    Returns:
        int: cluster id where this value belongs
    """    
    for cluster_id, cluster_range in enumerate(cluster_ranges):
        if value >= cluster_range[0] and value <= cluster_range[1]:
            return cluster_id
        
def divide_chunks(input_list, chunk_size):
    """Divides a list into chunks of the specified size.

    Args:
        input_list: The list to be divided.
        chunk_size: The desired size of each chunk.

    Returns:
        A list of lists, where each inner list is a chunk of the original list.
    """
    return [input_list[i:i + chunk_size] for i in range(0, len(input_list), chunk_size)]

    
def get_list_of_scores(chunk_id,return_dict,cluster_ids, distance_matrix, frame_ids_to_analyze, all_frame_ids, parallel = False):
    """using the distance matrix compute the modified silhouette scores for each frame

    Args:
        return_dict (dict): used for parallel processing
        cluster_ids (list of ints): cluster assignment for each frame
        distance_matrix (float square numpy matrix): distance of embeddings for each frame
        frame_ids_to_analyze (list of ints): frame ids we want to analyze from the entire session, for parallel processing
        all_frame_ids (list of ints): frame ids for each frame in the session
        parallel (bool, optional): parallel processing or not. Defaults to False.

    Returns:
        list of float silhouette scores
    """
    start_time = time.time()
    print(f"started process {chunk_id}")
    sil_scores = []
    for frame_id in frame_ids_to_analyze:
        cluster_id = cluster_ids[frame_id]
        # get the number of within cluster points
        within_cluster_num_points = np.count_nonzero(np.array(cluster_ids) == cluster_id)
        N_for_b = within_cluster_num_points - 1 # get how much in a bin
        # get a boolean for indexing all the within_cluster frames
        within_cluster_boolean = np.logical_and(np.array(cluster_ids) == cluster_id,
                                                np.array(all_frame_ids) != frame_id)
        # get the mean of all the within cluster_points
        a = float(np.mean(distance_matrix[frame_id, within_cluster_boolean]))
        other_cluster_boolean = np.array(cluster_ids) != cluster_id
        b = float(np.mean(distance_matrix[frame_id, other_cluster_boolean]))
        sil_score = (b - a) / max(a, b)
        sil_scores.append(sil_score)
    end_time = time.time()
    total_time = end_time - start_time
    print(f"ended process {chunk_id}, time elapsed {total_time}")
    if parallel:
        return_dict[frame_ids_to_analyze[0]] = sil_scores
    else:
        return sil_scores
    
def get_silhouette_scores(x_values, y_values, z_values,behavior_labels, num_clusters = 5, num_parallel = 0):
    """ get silhouette scores for each data points

    Args:
        x_values (list of floats): cebra embedding component 1
        y_values (list of floats): cebra embedding component 2
        z_values (list of floats): cebra embedding component 3
        behavior_labels (list of floats): behavior value for each frame which has its corresponding 3D embedding
        num_clusters (int, optional): number of clusters to make. Defaults to 5.
        num_parallel (int, optional): number of parallel processors to use. Defaults to 0.

    Returns:
        using a predefined number of clusters, break up the 3D embedding plot into clusters based on the behavior variable 
        and apply our modified silhouette scores
    """    
    # get the bins for imposing cluster
    cluster_ranges = get_cluster_ranges(behavior_labels, num_clusters=num_clusters)
    # get the cluster id for each data point
    cluster_ids = [get_cluster_index(value,cluster_ranges) for value in behavior_labels]
    # for each data point with and x y and z cebra embedding and a behavior label
    # get observations by dimensions matrix called coords and get distance matrix
    coords = np.array([x_values,y_values,z_values]).T
    distance_matrix = cdist(coords,coords, "euclidean")
    all_frame_ids = [i for i in range(len(cluster_ids))]
    # go through each data point getting its cluster in terms of behavior
    if num_parallel == 0:
        return get_list_of_scores(-1,{},cluster_ids, distance_matrix,all_frame_ids, all_frame_ids)
    else:
        chunks_of_frame_ids = divide_chunks(all_frame_ids, chunk_size = int(len(all_frame_ids) / num_parallel))
        manager = Manager()
        return_dict = manager.dict()
        # for each cluster label
        processes_list = []
        for chunk_id,chunk in enumerate(chunks_of_frame_ids):
            new_process = Process(target= get_list_of_scores, args = (chunk_id,return_dict,cluster_ids, distance_matrix,chunk, all_frame_ids, True))
            new_process.start()
            processes_list.append(new_process)
        for p in processes_list:
            p.join()
        all_scores = []
        for key in return_dict:
            all_scores += return_dict[key]
        return all_scores


def plot3D_color_map_matplotlib(x, y, z, colors, view_init = (30,-60), roll = None, cmap = None,
                   title = "", cbar_title = "", save_fig = False, s = 10, alpha = 1,
                   vmin = None, vmax = None, dpi = 2000, fig_size = (11,10)):
    """plot color map of 3D cebra embeddings with matplotlib

    Args:
        x (list of floats): list of cebra dimension 1
        y (list of floats): list of cebra dimension 2
        z (list of floats): list of cebra dimension 3
        other parameters: matplotlib parameters (look them up for more info)
    """
    # Plot
    fig = plt.figure(figsize=fig_size)
    ax = fig.add_subplot(projection='3d')
    ax.set_facecolor("white")
    sc = ax.scatter(x, y, z, c=colors, cmap=cmap, s=s, alpha = alpha,
                    vmin = vmin, vmax=vmax,marker= 'o',
                    linewidth=0, edgecolor='none')
    # Adding color bar to show angle mapping
    cbar = plt.colorbar(sc, ax=ax, shrink=0.5)
    cbar.set_label(cbar_title)
    # Labels for the axes
    ax.set_xlabel(f'cebra 1')
    ax.set_ylabel(f'cebra 2')
    ax.set_zlabel(f'cebra 3')
    ax.view_init(view_init[0], view_init[1], roll = roll)
    ax.grid(False)
    ax.set_facecolor("white")
    ax.xaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
    ax.yaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
    ax.zaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
    ax.set_rasterized(False)
    plt.savefig(f"tmp_figures/{title}_3D_embeds.pdf", dpi = dpi, transparent = True, bbox_inches = "tight")

########   training and getting embeddings ##########
def get_angle_v01(A, B):
    """
    Get the signed angle in degrees in the clockwise direction from A to B.
    [0, 180] if on the left. [0, -180) if on the right.
    
    Args:
        A: vector that is a size 2 list
        B: vector that is a size 2 list
        
    Returns:
        signed_angle_deg (int): angle between A and B
    """
    # Calculate the dot product of A and B
    dot_product = np.dot(A, B)
    
    # Calculate the magnitudes (norms) of A and B
    magnitude_A = np.linalg.norm(A)
    magnitude_B = np.linalg.norm(B)
    
    # Calculate the cosine of the angle between A and B
    cosine_theta = dot_product / (magnitude_A * magnitude_B)
    
    # Calculate the signed angle in radians using the arccosine
    signed_angle_rad = np.arccos(np.clip(cosine_theta, -1.0, 1.0))
    
    # Calculate the signed angle in degrees
    signed_angle_deg = np.degrees(signed_angle_rad)
    
    # Determine the sign of the angle (positive or negative)
    # based on the cross product of A and B
    cross_product = np.cross(np.append(A, 0), np.append(B, 0))
    if cross_product[2] < 0:
        signed_angle_deg = -signed_angle_deg
    
    return signed_angle_deg



def ego(NKT_self, NKT_other, ego_drop = 100, categorical = False):
    """ get egocentric angle between self and other

    Args:
        NKT_self (_type_): 3 by 2 numpy array
        NKT_other (_type_): 3 by 2 numpy array
        ego_drop (int, optional): cutoff for the angle behind the mouse which we make nan. Defaults to 100.
        categorical (bool, optional): whether or not we use binning approach (not used in final paper). Defaults to False.

    Returns:
        _type_: _description_
    """    
    # get the line going to other neck from self neck
    other_x_neck, other_y_neck = NKT_other[1][0], NKT_other[1][1]
    self_x_neck, self_y_neck = NKT_self[1][0], NKT_self[1][1]
    self_other_vector = [other_x_neck - self_x_neck, other_y_neck - self_y_neck]
    self_x_nose, self_y_nose = NKT_self[0][0], NKT_self[0][1]
    self_neck_nose_vector = [self_x_nose - self_x_neck,self_y_nose - self_y_neck]
    angle = get_angle_v01(self_neck_nose_vector,self_other_vector)
    bins = [[i, i+60] for i in range(-180,180,60)]
    bins_str = [f"{i}to{i+60}" for i in range(-180,180,60)]
    if categorical:
        for bin, bin_str in zip(bins, bins_str):
            if angle >= bin[0] and angle < bin[1]:
                return bin_str
    else:
        if abs(angle) > ego_drop:
            return np.nan
        return angle

def angle_from_x_axis(x, y):
    """ get angle from x axis with 0 origin
    Args:
        x (float): x coord
        y (float): y coord
    Returns:
        float: angle in degrees from the x axis 
    """    
    # Calculate the angle in radians using atan2
    angle_rad = math.atan2(y, x)
    # Convert radians to degrees
    angle_deg = math.degrees(angle_rad)
    return angle_deg



def distance_angle_from_origin(frame_3by2):
    """
    Calculate the Euclidean distance of a point from the origin (0, 0).

    Args:
        point: A tuple or list representing the point (x, y).

    Returns:
        The distance from the origin.
    """
    if frame_3by2.shape[0] != 3 or frame_3by2.shape[1] != 2:
        print(f"error: frame_3by2.shape[0] {frame_3by2.shape[0]}")
    x,y = frame_3by2[0,0],frame_3by2[0,1]
    return math.sqrt(x**2 + y**2), angle_from_x_axis(x,y)

def distance_two_mice(frame_3by2_self, frame_3by2_other):
    '''
    Calculate distance between two mice
    
    params: 3 by 2 sleap coords for self and other mouse
    '''
    x_self,y_self = frame_3by2_self[1,0],frame_3by2_self[1,1]
    x_other,y_other = frame_3by2_other[1,0],frame_3by2_other[1,1]
    return math.dist([x_self,y_self], [x_other, y_other])

def distance_from_rz(frame_3by2, rz):
    '''
    computes distance from reward zone by the nose
    
    parameters: SLEAP coords 3 by 2 at this frame, and a size 2 list of x and y rz coords
    returns: distance from rz (float)
    '''
    x_nose,y_nose = frame_3by2[0,0],frame_3by2[0,1]
    x_neck,y_neck = frame_3by2[1,0],frame_3by2[1,1]
    x_torso,y_torso = frame_3by2[2,0],frame_3by2[2,1]
    x_rz, y_rz = rz[0],rz[1]
    return math.dist([x_nose,y_nose], [x_rz, y_rz])


def get_whether_mouse_is_heading_in_ultimate_direction(ultimate_zone, head_direction):
    ''' 
    Get if a mouse is facing the direction it ends up choosing in this trial

    parameters:
    - the ultimate zone from [north, east, south, west]
    - the head direction of the mouse in degrees
    
    returns:
    - bool: whether or not mouse is heading the ultimate direction
    '''
    direction_to_degrees = {"south":[45,135], "east": [315,45], "north": [225,315], "west": [135,225]}
    degree1,degree2 = direction_to_degrees[ultimate_zone]
    if ultimate_zone == "east":
        if head_direction > degree1:
            return True
        elif head_direction < degree2 and head_direction >= 0:
            return True
        else:
            return False
    else:
        if head_direction > degree1 and head_direction < degree2:
            return True
        else:
            return False



def get_head_direction_one_frame(NKT_data_one_frame):
    ''' 
    Get the direction that a single mouse is facing

    parameters:
    - NKT_data_one_frame: a 2D array of the x,y coordinates of the different 
      body positions for one frame in one trial for a single animal
    returns:
    - the degrees that the nose is in with respect to x-axis
    '''
    # take in a 2D array of the x,y coordinates of the different 
    # body positions for one frame in one trial
    # neck minus nose
    delta_x = NKT_data_one_frame[0][0] - NKT_data_one_frame[1][0]
    delta_y = NKT_data_one_frame[0][1] - NKT_data_one_frame[1][1]
    # Calculate the angle in radians
    angle_rad = math.atan2(delta_y, delta_x)
    # Convert to degrees
    angle_deg = math.degrees(angle_rad)
    # Adjust for negative angles
    if angle_deg < 0:
        angle_deg += 360
    return angle_deg

def is_in_fov_single_frame(person_pos, person_angle, fov_angle, object_pos):
    """
    Check if an object is within the field of view of a person.
    
    parameters:
    - person_pos: tuple (x, y) representing the person's position.
    - person_angle: the angle in degrees (relative to the positive x-axis) that the person is facing.
    - fov_angle: the field of view angle in degrees (e.g., 60 for a 60-degree FOV).
    - object_pos: tuple (x, y) representing the object's position.
    
    returns:
    - True if the object is in the field of view, False otherwise.
    """
    
    # Convert the person's facing angle and FOV angle to radians
    person_angle_rad = math.radians(person_angle)
    fov_angle_rad = math.radians(fov_angle)
    
    # Calculate the vector from the person to the object
    dx = object_pos[0] - person_pos[0]
    dy = object_pos[1] - person_pos[1]
    object_angle = math.atan2(dy, dx)  # Angle to the object relative to the positive x-axis
    
    # Normalize the angles to [0, 2*pi] to avoid negative values
    person_angle_rad = person_angle_rad % (2 * math.pi)
    object_angle = object_angle % (2 * math.pi)
    
    # Check if the object is within the field of view
    angle_diff = abs(object_angle - person_angle_rad)
    
    # Adjust the angle difference to the range [0, pi] (since angles are circular)
    if angle_diff > math.pi:
        angle_diff = 2 * math.pi - angle_diff
    
    # Check if the object is within the FOV
    return 1 if angle_diff <= fov_angle_rad / 2 else 0



def either_mouse_is_in_rzs_radius(frame_3by2_list,radius,rzs):
    """
    Check if either mouse is in any reward zones radius
    
    parameters:
    - frame_3by2_list: two mouse's position of 3 different body points
    - radius: radius around the reward zone
    - rz: 4 reward zone coordiantes list of 4 size 2 x,y tuples
    
    returns:
    - True if any bp from any mouse is in any rz radius
    """
    distances = []
    for rz in rzs: # each rz
        for frame_3by2 in frame_3by2_list: # each mouse
            for body_point_index in range(frame_3by2.shape[0]): # each body point in that mouse
                x_bp,y_bp = frame_3by2[body_point_index,0],frame_3by2[body_point_index,1]
                x_rz, y_rz = rz[0],rz[1]
                distance_between_bp_and_rz = math.dist([x_bp,y_bp], [x_rz, y_rz])
                distances.append(distance_between_bp_and_rz)
                if distance_between_bp_and_rz <= radius:
                    return True
    return False

def get_rotated_all_frames(SLEAP_file_path, stable_data_path, landmarks_path, is_m1, small_radius = 3, ego_drop = 160, categorical_ego = False):
    '''
    rotates data to N/E alignment
    
    parameters:
    - SLEAP avi.mat file containing a (num_frames, 3 body_points, 2 x/y, 2 mouse id) matrix
    - stable data file in mat.csv generated over matlab for easy read in (must match SLEAP file)
    - landmarks path to json that is for this particular session
    
    returns:
    - SLEAP_data_rotated_all: rotated SLEAP data from every frame (4D np array)
    - indices_of_trials_each_frame: indices of frames that contain trials (list of 0 and 1)
    - conditions_dict: behavioral variables we can use for CEBRA, a dict with lists of floats as values
    - self_waiting_in_reward_zone_each_trial, other_waiting_in_reward_zone_each_trial: list of ints for how many frames self and other mouse stayed in reward zone each trial (not used in analysis for paper)
    '''
    rz1 = [0, 22.5]  # north zone
    rz2 = [22.5, 0]  # east
    rz3 = [0, -22.5]  # south
    rz4 = [-22.5, 0]  # west
    rzs = [rz1, rz2, rz3, rz4]
    radius_in_rz = 10

    with open(landmarks_path, 'r') as file:
        landmarks = json.load(file)
    landmarks = {key:np.array(value) for key,value in landmarks.items()}
    stable_data = pd.read_csv(stable_data_path)
    SLEAP_data_YC017YC018phase4_09182023094005 = np.array(sio.loadmat(SLEAP_file_path)["SLEAP_coords"]) # (81712, 3, 2, 2)

    shape_sleap = SLEAP_data_YC017YC018phase4_09182023094005.shape
    print(f"shape_sleap {shape_sleap}")
    SLEAP_data_rotated_all = np.zeros(shape_sleap)
    SLEAP_data_rotated_all[:] = np.nan
    indices_of_trials_each_frame = np.zeros((shape_sleap[0],))
    indices_of_trials_each_frame[:] = np.nan
    correct_each_frame = np.zeros((shape_sleap[0],))
    correct_each_frame[:] = np.nan
    self_ending_zone = np.zeros((shape_sleap[0],))
    self_ending_zone[:] = np.nan
    self_ending_zone_NE_aligned = np.zeros((shape_sleap[0],))
    self_ending_zone_NE_aligned[:] = np.nan
    is_leader_each_frame = np.zeros((shape_sleap[0],))
    is_leader_each_frame[:] = np.nan
    frame_in_trial_each_frame = np.zeros((shape_sleap[0],))
    frame_in_trial_each_frame[:] = np.nan

    frame_in_iti_each_frame = np.zeros((shape_sleap[0],))
    frame_in_iti_each_frame[:] = np.nan
    
    frame_from_back_in_trial_each_frame = np.zeros((shape_sleap[0],))
    frame_from_back_in_trial_each_frame[:] = np.nan

    is_initiator_each_frame = np.zeros((shape_sleap[0],))
    is_initiator_each_frame[:] = np.nan
    
    is_initiator_next_trial_each_iti_frame = np.zeros((shape_sleap[0],))
    is_initiator_next_trial_each_iti_frame[:] = np.nan
    
    frame_back_from_end_of_iti_each_iti_frame = np.zeros((shape_sleap[0],)) 
    frame_back_from_end_of_iti_each_iti_frame[:] = np.nan
    
    previous_trial_was_correct_each_iti_frame = np.zeros((shape_sleap[0],))
    previous_trial_was_correct_each_iti_frame[:] = np.nan
    
    self_distance_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_distance_each_frame[:] = np.nan
    
    self_distance_from_final_port_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_distance_from_final_port_each_frame[:] = np.nan
    
    self_angle_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_angle_each_frame[:] = np.nan
    
    other_distance_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_distance_each_frame[:] = np.nan
    
    self_in_other_fov_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_in_other_fov_each_frame[:] = np.nan
    
    ego_angle_from_self_each_frame = np.full( shape = (shape_sleap[0],), fill_value=np.nan, dtype = np.float16) if categorical_ego == False else np.full(shape = (shape_sleap[0],), fill_value= "NAN", dtype = "O") # "back", "left_back", "right_back", "left_side" "right_side" "left_front" "right_front" "front" 
 
    other_in_self_fov_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_in_self_fov_each_frame[:] = np.nan
    
    other_distance_from_final_port_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_distance_from_final_port_each_frame[:] = np.nan
    
    other_angle_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_angle_each_frame[:] = np.nan
    
    self_other_distance_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_other_distance_each_frame[:] = np.nan
    
    either_mouse_is_in_rzs_radius_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    either_mouse_is_in_rzs_radius_each_frame[:] = np.nan
    
    rotated_self_distance_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    rotated_self_distance_each_frame[:] = np.nan
    rotated_self_angle_each_frame = np.zeros((shape_sleap[0],), dtype = np.float16)
    rotated_self_angle_each_frame[:] = np.nan
    previous_trial_last_index_plus1 = int(0) # keeps track of the last frame included in the trial in 0 index
    previous_trial_type = 0
    previous_trial_correct_this_iti = np.nan
    previous_self_reward_zone = np.nan
    previous_other_reward_zone = np.nan
    
    # large
    # self
    self_in_reward_port_frames_back_from_end_large_radius = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_in_reward_port_frames_back_from_end_large_radius[:] = np.nan
    self_in_reward_port_frames_from_beginning_large_radius  = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_in_reward_port_frames_from_beginning_large_radius[:] = np.nan
    # other
    other_in_reward_port_frames_back_from_end_large_radius = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_in_reward_port_frames_back_from_end_large_radius[:] = np.nan
    other_in_reward_port_frames_from_beginning_large_radius  = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_in_reward_port_frames_from_beginning_large_radius[:] = np.nan
    
    # small
    # self
    self_in_reward_port_frames_from_beginning_small_radius  = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_in_reward_port_frames_from_beginning_small_radius[:] = np.nan
    self_in_reward_port_frames_from_end_small_radius  = np.zeros((shape_sleap[0],), dtype = np.float16)
    self_in_reward_port_frames_from_end_small_radius[:] = np.nan
    # other
    other_in_reward_port_frames_from_beginning_small_radius  = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_in_reward_port_frames_from_beginning_small_radius[:] = np.nan
    other_in_reward_port_frames_from_end_small_radius  = np.zeros((shape_sleap[0],), dtype = np.float16)
    other_in_reward_port_frames_from_end_small_radius[:] = np.nan
    trial_to_last_arr = {}
    m_id_flag = 1 if is_m1 else 2
    other_m_id_flag = 2 if is_m1 else 1
    iti_counter = 0
    
    # count the number of waiting minutes each trial
    self_waiting_in_reward_zone_each_trial = []
    other_waiting_in_reward_zone_each_trial = []
    for trial_index, trial in stable_data.iterrows():
        # iti range is from the last trial's end to the current trials beginning for the trials in the middle
        # the last trial index is set to 0 for the first iti (which is not really an iti but a before session interval, more accurately)
        iti_range = range(previous_trial_last_index_plus1, int(trial["led_init"]) - 1)
        iti_length = len([i for i in iti_range])
        previous_trial_last_index_plus1 = int(trial["led_end"])
        last_frame_in_trial = int(trial["led_end"]) - 1
        trial_range = range(int(trial["led_init"]) - 1, int(trial["led_end"]))
        trial_length = len([i for i in trial_range])
        trial_type = int(trial["trial_type"]) - 1
        correct_trial = int(trial["correct"])
        
        # self zone
        self_zone_this_trial = np.nan if np.isnan(trial[f"m{m_id_flag}_zone"]) else int(trial[f"m{m_id_flag}_zone"])
        self_reward_port_location_this_trial = np.nan if np.isnan(self_zone_this_trial) else rzs[int(self_zone_this_trial) - 1]
        # get the previous trials port location for iti and update previous to current
        # minus 1 to 0 index (converting from matlab to python)
        self_reward_port_location_previous_trial = np.nan if trial_index == 0 or np.isnan(stable_data.iloc[trial_index - 1,:][f"m{m_id_flag}_zone"]) \
                                                    else rzs[int(stable_data.iloc[trial_index - 1,:][f"m{m_id_flag}_zone"]) - 1]
        
        
        # other zone
        other_zone_this_trial = np.nan if np.isnan(trial[f"m{other_m_id_flag}_zone"]) else int(trial[f"m{other_m_id_flag}_zone"])
        other_reward_port_location_this_trial = np.nan if np.isnan(other_zone_this_trial) else rzs[int(other_zone_this_trial) - 1]
        # get previous trials port location for iti and update previous to current
        other_reward_port_location_previous_trial = np.nan if trial_index == 0 or np.isnan(stable_data.iloc[trial_index - 1,:][f"m{other_m_id_flag}_zone"]) \
                                                    else rzs[int(stable_data.iloc[trial_index - 1,:][f"m{other_m_id_flag}_zone"]) - 1]

        self_zone_NE_aligned_this_trial = np.nan if np.isnan(trial[f"m{m_id_flag}_zone"]) else convert_target_zone_to_new_space(int(trial[f"m{m_id_flag}_zone"]),trial_type)

        if np.isnan(trial["leader"]):
            leader_this_trial = np.nan
        else:
            leader_this_trial = 1 if int(trial["leader"]) == m_id_flag else 0
        initiator_this_trial = 1 if int(trial["initiator"]) == m_id_flag else 0
        m1_last_arr = np.nan if np.isnan(trial["m1_last_arr"]) else int(trial["m1_last_arr"])
        m2_last_arr = np.nan if np.isnan(trial["m2_last_arr"]) else int(trial["m2_last_arr"])
        self_last_arr = m1_last_arr if m_id_flag == 1 else m2_last_arr
        other_last_arr = m2_last_arr if m_id_flag == 1 else m1_last_arr
        trial_to_last_arr[trial_index + 1] = {"self": self_last_arr, "other": other_last_arr}
        for mouse_id in [0,1]:
            # do iti leading up to this trial
            for frame_index, frame_num in enumerate(iti_range):
                this_frame = SLEAP_data_YC017YC018phase4_09182023094005[frame_num,:,:,mouse_id]
                rotated_frame, cm_points = pix2cm_then_rotate(this_frame, landmarks, previous_trial_type)
                SLEAP_data_rotated_all[frame_num,:,:,mouse_id] = rotated_frame
                if mouse_id == (m_id_flag - 1):
                    indices_of_trials_each_frame[frame_num] = iti_counter
                    rotated_distance, rotated_angle = distance_angle_from_origin(rotated_frame)
                    rotated_self_distance_each_frame[frame_num] = rotated_distance
                    rotated_self_angle_each_frame[frame_num] = rotated_angle
                    if trial_index != 0: # do not want to consider the first iti leading up to trial 1
                        frame_in_iti_each_frame[frame_num] = frame_index
                    distance, angle = distance_angle_from_origin(cm_points)
                    self_distance_each_frame[frame_num] = distance
                    self_angle_each_frame[frame_num] = angle
                    other_mouse_id = 1 if mouse_id == 0 else 0
                    other_frame = SLEAP_data_YC017YC018phase4_09182023094005[frame_num,:,:,other_mouse_id]
                    other_rotated_frame, other_cm_points = pix2cm_then_rotate(other_frame, landmarks, previous_trial_type)
                    self_other_distance_each_frame[frame_num] = distance_two_mice(cm_points, other_cm_points)
                    other_distance, other_angle = distance_angle_from_origin(other_cm_points)
                    other_distance_each_frame[frame_num] = other_distance
                    other_angle_each_frame[frame_num] = other_angle
                    other_distance_from_final_port_each_frame
                    # update the frame from end of iti
                    frame_back_from_end_of_iti_each_iti_frame[frame_num] = int(iti_length) - frame_index
                    # update the previous trial was correct
                    previous_trial_was_correct_each_iti_frame[frame_num] = previous_trial_correct_this_iti
                    # update next trial is initiator
                    is_initiator_next_trial_each_iti_frame[frame_num] = initiator_this_trial
                    self_distance_from_final_port_each_frame[frame_num] =  np.nan if np.any(np.isnan(self_reward_port_location_previous_trial)) \
                                                                    else distance_from_rz(cm_points, self_reward_port_location_previous_trial)
                    other_distance_from_final_port_each_frame[frame_num] =  np.nan if np.any(np.isnan(other_reward_port_location_previous_trial)) \
                                                                    else distance_from_rz(other_cm_points, other_reward_port_location_previous_trial)
                    either_mouse_is_in_rzs_radius_each_frame[frame_num] = either_mouse_is_in_rzs_radius([cm_points,other_cm_points],radius = radius_in_rz,rzs = rzs)
                    ego_angle_from_self_each_frame[frame_num] = ego(cm_points, other_cm_points, categorical= categorical_ego, ego_drop= ego_drop)
                    other_in_self_fov = is_in_fov_single_frame(person_pos = cm_points[0,:], person_angle = get_head_direction_one_frame(cm_points), 
                                                                fov_angle = 200, object_pos = other_cm_points[0,:])
                    other_in_self_fov_each_frame[frame_num] = other_in_self_fov
            # do for this trial
            self_num_frames_in_reward_port_larger_radius = 0
            other_num_frames_in_reward_port_larger_radius = 0
            
            self_num_frames_in_reward_port_small_radius = 0
            other_num_frames_in_reward_port_small_radius = 0
            
            
            for frame_index, frame_num in enumerate(trial_range):
                this_frame = SLEAP_data_YC017YC018phase4_09182023094005[frame_num,:,:,mouse_id]
                rotated_frame, cm_points  = pix2cm_then_rotate(this_frame, landmarks, trial_type)
                SLEAP_data_rotated_all[frame_num,:,:,mouse_id] = rotated_frame
                if mouse_id == (m_id_flag - 1):
                    indices_of_trials_each_frame[frame_num] = trial_index + 1
                    correct_each_frame[frame_num] = correct_trial
                    frame_in_trial_each_frame[frame_num] = frame_index
                    frame_from_back_in_trial_each_frame[frame_num] = trial_length - frame_index
                    is_leader_each_frame[frame_num] = leader_this_trial
                    is_initiator_each_frame[frame_num] = initiator_this_trial
                    self_ending_zone[frame_num] = self_zone_this_trial
                    self_ending_zone_NE_aligned[frame_num] = self_zone_NE_aligned_this_trial
                    rotated_distance, rotated_angle = distance_angle_from_origin(rotated_frame)
                    rotated_self_distance_each_frame[frame_num] = rotated_distance
                    rotated_self_angle_each_frame[frame_num] = rotated_angle
                    
                    distance, angle = distance_angle_from_origin(cm_points)
                    self_distance_each_frame[frame_num] = distance
                    self_angle_each_frame[frame_num] = angle
                    # update whether we are in reward port by how long we have been in there
                    if frame_num >= (self_last_arr - 1):
                        self_num_frames_in_reward_port_larger_radius += 1
                        self_in_reward_port_frames_back_from_end_large_radius[frame_num] = last_frame_in_trial - frame_num + 1
                        self_in_reward_port_frames_from_beginning_large_radius[frame_num] = self_num_frames_in_reward_port_larger_radius
                    else:
                        self_in_reward_port_frames_back_from_end_large_radius[frame_num] = -1
                        self_in_reward_port_frames_from_beginning_large_radius[frame_num] = -1
                        
            
                    if frame_num >= (other_last_arr - 1):
                        other_num_frames_in_reward_port_larger_radius += 1
                        other_in_reward_port_frames_back_from_end_large_radius[frame_num] = last_frame_in_trial - frame_num + 1
                        other_in_reward_port_frames_from_beginning_large_radius[frame_num] = other_num_frames_in_reward_port_larger_radius
                    else:
                        other_in_reward_port_frames_back_from_end_large_radius[frame_num] = -1
                        other_in_reward_port_frames_from_beginning_large_radius[frame_num] = -1
                        
                    # look at other distance and angle and self other distance
                    other_mouse_id = 1 if mouse_id == 0 else 0
                    other_frame = SLEAP_data_YC017YC018phase4_09182023094005[frame_num,:,:,other_mouse_id]
                    other_rotated_frame, other_cm_points = pix2cm_then_rotate(other_frame, landmarks, trial_type)
                    self_other_distance_each_frame[frame_num] = distance_two_mice(cm_points, other_cm_points)
                    other_distance, other_angle = distance_angle_from_origin(other_cm_points)
                    other_distance_each_frame[frame_num] = other_distance
                    other_angle_each_frame[frame_num] = other_angle
                    
                    # get whether one mouse is in another's field of view
                    other_in_self_fov = is_in_fov_single_frame(person_pos = cm_points[0,:], person_angle = get_head_direction_one_frame(cm_points), 
                                                                fov_angle = 200, object_pos = other_cm_points[0,:])
                    other_in_self_fov_each_frame[frame_num] = other_in_self_fov
                    self_in_other_fov = is_in_fov_single_frame(person_pos = other_cm_points[0,:], person_angle = get_head_direction_one_frame(other_cm_points), 
                                                                fov_angle = 200, object_pos = cm_points[0,:])
                    
                    ego_angle_from_self_each_frame[frame_num] = ego(cm_points, other_cm_points, ego_drop= ego_drop, categorical= categorical_ego)
                    self_in_other_fov_each_frame[frame_num] = self_in_other_fov
                    # compute distance to reward port
                    self_distance_from_final_port_each_frame[frame_num] = np.nan if np.any(np.isnan(self_reward_port_location_this_trial)) \
                                                                    else distance_from_rz(cm_points, self_reward_port_location_this_trial)
                    other_distance_from_final_port_each_frame[frame_num] = np.nan if np.any(np.isnan(other_reward_port_location_this_trial)) \
                                                                    else distance_from_rz(other_cm_points, other_reward_port_location_this_trial)
                    # update num frames in small radius
                    # self
                    if frame_num >= (self_last_arr - 1) and distance_from_rz(cm_points, self_reward_port_location_this_trial) <= small_radius:
                        self_num_frames_in_reward_port_small_radius += 1
                        self_in_reward_port_frames_from_beginning_small_radius[frame_num] = self_num_frames_in_reward_port_small_radius
                        self_in_reward_port_frames_from_end_small_radius[frame_num] = last_frame_in_trial - frame_num + 1
                    else:
                        self_in_reward_port_frames_from_beginning_small_radius[frame_num] = -1
                        self_in_reward_port_frames_from_end_small_radius[frame_num] = -1
                        if self_num_frames_in_reward_port_small_radius >= 1:
                            for past_frame_num in range(frame_num - self_num_frames_in_reward_port_small_radius, frame_num):
                                self_in_reward_port_frames_from_beginning_small_radius[past_frame_num] = -1
                                self_in_reward_port_frames_from_end_small_radius[past_frame_num] = -1
                            self_num_frames_in_reward_port_small_radius = 0
                    # other
                    if frame_num >= (other_last_arr - 1) and distance_from_rz(other_cm_points, other_reward_port_location_this_trial) <= small_radius:
                        other_num_frames_in_reward_port_small_radius += 1
                        other_in_reward_port_frames_from_beginning_small_radius[frame_num] = other_num_frames_in_reward_port_small_radius
                        other_in_reward_port_frames_from_end_small_radius[frame_num] = last_frame_in_trial - frame_num + 1

                    else:
                        other_in_reward_port_frames_from_beginning_small_radius[frame_num] = -1
                        other_in_reward_port_frames_from_end_small_radius[frame_num] = -1
                        # adding in a tracker so that we only get the frames where the mouse sticks it out right on top of port
                        if other_num_frames_in_reward_port_small_radius >= 1:
                            for past_frame_num in range(frame_num - other_num_frames_in_reward_port_small_radius, frame_num):
                                other_in_reward_port_frames_from_beginning_small_radius[past_frame_num] = -1
                                other_in_reward_port_frames_from_end_small_radius[past_frame_num] = -1
                            other_num_frames_in_reward_port_small_radius = 0
                    either_mouse_is_in_rzs_radius_each_frame[frame_num] = \
                        either_mouse_is_in_rzs_radius([cm_points,other_cm_points],radius = radius_in_rz,rzs = rzs)
                    

            self_waiting_in_reward_zone_each_trial.append(self_num_frames_in_reward_port_larger_radius)
            other_waiting_in_reward_zone_each_trial.append(other_num_frames_in_reward_port_larger_radius)
            # get the iti range at the end
            if trial_index == (stable_data.shape[0] - 1):
                iti_range = range(previous_trial_last_index_plus1, shape_sleap[0])
                iti_counter -= 1
                for frame_index, frame_num in enumerate(iti_range):
                    this_frame = SLEAP_data_YC017YC018phase4_09182023094005[frame_num,:,:,mouse_id]
                    rotated_frame, cm_points = pix2cm_then_rotate(this_frame, landmarks, previous_trial_type)
                    SLEAP_data_rotated_all[frame_num,:,:,mouse_id] = rotated_frame
                    if mouse_id == (m_id_flag - 1):
                        indices_of_trials_each_frame[frame_num] = iti_counter
                        rotated_distance, rotated_angle = distance_angle_from_origin(rotated_frame)
                        rotated_self_distance_each_frame[frame_num] = rotated_distance
                        rotated_self_angle_each_frame[frame_num] = rotated_angle
                        frame_in_iti_each_frame[frame_num] = frame_index
                        distance, angle = distance_angle_from_origin(cm_points)
                        self_distance_each_frame[frame_num] = distance
                        self_angle_each_frame[frame_num] = angle
                        other_frame = SLEAP_data_YC017YC018phase4_09182023094005[frame_num,:,:,other_mouse_id]
                        other_rotated_frame, other_cm_points = pix2cm_then_rotate(other_frame, landmarks, previous_trial_type)
                        self_other_distance_each_frame[frame_num] = distance_two_mice(cm_points, other_cm_points)
                        # previous trial correct
                        previous_trial_was_correct_each_iti_frame[frame_num] = correct_trial
                        other_distance, other_angle = distance_angle_from_origin(other_cm_points)
                        other_distance_each_frame[frame_num] = other_distance
                        other_angle_each_frame[frame_num] = other_angle
                        self_distance_from_final_port_each_frame[frame_num] = np.nan if np.any(np.isnan(self_reward_port_location_previous_trial)) \
                                                                    else distance_from_rz(cm_points, self_reward_port_location_previous_trial)
                        other_distance_from_final_port_each_frame[frame_num] = np.nan if np.any(np.isnan(other_reward_port_location_previous_trial)) \
                                                                        else distance_from_rz(other_cm_points, other_reward_port_location_previous_trial)
                        either_mouse_is_in_rzs_radius_each_frame[frame_num] = \
                        either_mouse_is_in_rzs_radius([cm_points,other_cm_points],radius = radius_in_rz,rzs = rzs)
                        ego_angle_from_self_each_frame[frame_num] = ego(cm_points, other_cm_points, ego_drop= ego_drop, categorical=categorical_ego)
                        other_in_self_fov = is_in_fov_single_frame(person_pos = cm_points[0,:], person_angle = get_head_direction_one_frame(cm_points), 
                                                                    fov_angle = 200, object_pos = other_cm_points[0,:])
                        other_in_self_fov_each_frame[frame_num] = other_in_self_fov

        # now that we have rotated each frame of the iti based on the previous trial type, we update with the current trial
        previous_trial_type = trial_type
        previous_trial_correct_this_iti = correct_trial
        iti_counter -= 1
    conditions_dict = { "self_port_distance": self_distance_from_final_port_each_frame,
                        "other_port_distance": other_distance_from_final_port_each_frame,
                        "self_other_distance": self_other_distance_each_frame,
                       "rotated_self_distance":rotated_self_distance_each_frame, "rotated_self_angle": rotated_self_angle_each_frame,
                       "self_distance":self_distance_each_frame, "self_angle": self_angle_each_frame,
                       "other_distance":other_distance_each_frame, "other_angle": other_angle_each_frame,
                       "self_zone": self_ending_zone, "self_zone_NE_aligned": self_ending_zone_NE_aligned,
                       "correct": correct_each_frame, "is_leader": is_leader_each_frame,
                       "is_initiator":is_initiator_each_frame, "time_in_trial":frame_in_trial_each_frame,
                       "frame_from_back_in_trial": frame_from_back_in_trial_each_frame,
                       "frame_in_iti":frame_in_iti_each_frame,
                       "frame_back_from_end_of_iti": frame_back_from_end_of_iti_each_iti_frame,
                       "previous_trial_was_correct_in_iti": previous_trial_was_correct_each_iti_frame,
                       "is_initiator_next_trial_in_iti": is_initiator_next_trial_each_iti_frame,
                       "self_in_reward_port_from_back_end_large_radius": self_in_reward_port_frames_back_from_end_large_radius,
                       "other_in_reward_port_from_back_end_large_radius": other_in_reward_port_frames_back_from_end_large_radius,
                       "self_in_reward_port_from_begin_large_radius": self_in_reward_port_frames_from_beginning_large_radius,
                       "other_in_reward_port_from_begin_large_radius": other_in_reward_port_frames_from_beginning_large_radius,
                       "self_in_reward_port_from_begin_small_radius": self_in_reward_port_frames_from_beginning_small_radius,
                       "other_in_reward_port_frames_from_begin_small_radius": other_in_reward_port_frames_from_beginning_small_radius,
                       "self_in_reward_port_frames_from_end_small_radius":self_in_reward_port_frames_from_end_small_radius,
                       "other_in_reward_port_frames_from_end_small_radius":other_in_reward_port_frames_from_end_small_radius,
                       "self_in_other_fov": self_in_other_fov_each_frame,
                       "other_in_self_fov": other_in_self_fov_each_frame,
                       "either_mouse_is_in_rzs_radius_each_frame": either_mouse_is_in_rzs_radius_each_frame,
                       "ego_angle_from_self_each_frame":ego_angle_from_self_each_frame
                       }
    return SLEAP_data_rotated_all, indices_of_trials_each_frame, conditions_dict, self_waiting_in_reward_zone_each_trial, other_waiting_in_reward_zone_each_trial


def pix2cm_landmks(in_pts, landmks):

    """
    go from pix coords to cm
    
    parameters:
    - landmks: a dict specifying place of landmarks in cm
    - in_pts: N b 2 pix coords
    
    returns:
        coords in cm space with center at origins
    """
    side_length = 45  # side of the arena in centimeters
    
    # Extract landmark coordinates
    bl = landmks['bl']  # bottom left 
    br = landmks['br']  # bottom right
    tr = landmks['tr']  # top right
    tl = landmks['tl']  # top left
    ml = landmks['ml']  # middle left
    mr = landmks['mr']  # middle right
    mt = landmks['mt']  # middle top
    mb = landmks['mb']  # middle bottom
    c = landmks['c']    # center, defined as [0, 0] in cm coordinates
    
    # Compute conversion factor
    # for x axis
    bx = np.linalg.norm(br - bl)  # bottom side on x
    mx = np.linalg.norm(mr - ml)  # middle length
    avg_x = (bx + mx) / 2
    x_slope = avg_x / side_length  # pixel/cm
    x_intercept = c[0]
    
    # for y axis
    ly = np.linalg.norm(bl - tl)  # left side on y
    my = np.linalg.norm(mb - mt)
    avg_y = (ly + my) / 2
    y_slope = avg_y / side_length  # pixel/cm
    y_intercept = c[1]
    
    # Ensure input is an Nx2 array (list of coordinates)
    if in_pts.shape[1] == 2:
        out_pts = np.zeros_like(in_pts)
        out_pts[:, 0] = (in_pts[:, 0] - x_intercept) / x_slope
        out_pts[:, 1] = -(in_pts[:, 1] - y_intercept) / y_slope
        return out_pts
    else:
        raise ValueError('Input must be an N by 2 array!')


def get_angle_v01(A, B):
    """
    Get the signed angle in degrees in the clockwise direction from vector A to vector B.
    """
    # Calculate the dot product of A and B
    dot_product = np.dot(A, B)
    
    # Calculate the magnitudes (norms) of A and B
    magnitude_A = np.linalg.norm(A)
    magnitude_B = np.linalg.norm(B)
    
    # Calculate the cosine of the angle between A and B
    cosine_theta = dot_product / (magnitude_A * magnitude_B)
    
    # Calculate the signed angle in radians using the arccosine
    signed_angle_rad = np.arccos(np.clip(cosine_theta, -1.0, 1.0))  # clip to avoid numerical issues
    
    # Convert the signed angle from radians to degrees
    signed_angle_deg = np.degrees(signed_angle_rad)
    
    # Calculate the cross product to determine the sign of the angle
    cross_product = np.cross(np.append(A, 0), np.append(B, 0))  # Extend vectors to 3D for cross product
    if cross_product[2] < 0:
        signed_angle_deg = -signed_angle_deg
    
    return signed_angle_deg

def get_angle_from_horizon(y_coords, x_coords):
    """
    Calculate the angle from the horizon (0 degrees along the x-axis) for each (y, x) coordinate.
    Returns angles in the range [0, 360) degrees.
    """
    # Calculate the angles using atan2, which gives the angle in radians
    angles = np.degrees(np.arctan2(y_coords, x_coords))
    
    # Adjust the angles to be in the range [0, 360)
    angles[angles < 0] += 360
    
    return angles

def convert_target_zone_to_new_space(target_zone, trial_type, return_str = False):
    '''
    figure out what zone we are talking about in the north/east space

    parameters:
    - target_zone: 1,2,3,4 for north, east, south or west
    - trial_type: which of the 6 types defining where the ports are, 0 indexed

    returns:
    - whether this zone is in the north (1) or in the east (2)
    '''
    # this i acquired from herbert, and it is based on how the rotation
    # matrices are computed for each trial type
    what_is_in_north_for_each_trial_type = [1, 2, 3, 4, 1, 2]
    current_in_north = what_is_in_north_for_each_trial_type[trial_type]
    if current_in_north == target_zone:
        return "north" if return_str else 1
    else:
        return "east" if return_str else 2
    
def pix2cm_then_rotate(points, landmarks,trial_type, testing = False):
    '''
    convert to cm and rotate to be N/E aligned

    parameters:
    - points: 3 by 2 array of SLEAP points in pix space
    - landmarks: dict of task landmarks
    - trial type 0 indexed (0-5)
    
    returns:
    - 3 by 2 array of rotated coords now in cm space
    '''
    cm_points = pix2cm_landmks(in_pts = points, landmks = landmarks)
    rotated_coords = rotate_coords(cm_points, trial_type= trial_type)
    return rotated_coords, cm_points


def rotate_coords(coords, trial_type):
    '''
    rotate coords in cm space

    parameters:
    - coords: N by 2 array with coords where the 2 is for the x and y coords
            and N is the number of x,y points you want to rotate
    - trial_type: trial type 0-indexed of the 6 types that described where ports are

    returns:
    rotated N by 2 coords
    '''
    # Rotation angles for trial types 1-6
    thetas = [0, np.pi / 2, np.pi, -np.pi / 2, 0, np.pi / 2]
    theta = thetas[trial_type]  # Adjust indexing to 0-based in Python
    rotation_matrix = np.array([[np.cos(theta), -np.sin(theta)], [np.sin(theta), np.cos(theta)]])
    N = coords.shape[0]
    return np.dot(rotation_matrix, coords.T).T


######## training, getting embeddings and gridsearch ############



def get_neural_and_behavioral_data_dict(social_foraging_data_path, tmux_session_name, output_dir):
    """organize neural data and behavior into lists for CEBRA, for one animal

    Args:
        social_foraging_data_path (str): path to dataset
        tmux_session_name (_type_): str like "69" denoting the animal which was used to do parallel processing across tmux sessions with a script per animal
         where a single tmux_session_name denotes a single animal (and all of the sessions for that particular animal)
        output_dir (str): where to output the organzied data

    Returns:
        mouse_and_date_list: list of strings for all of the sessions for this animal
        neural_data_list: list of cleaned up numpy arrays with neural data for each session
        conditions_dict_list: list of dicts for each session with each dict having lists of different behavioral variables we could use in CEBRA
        indices_of_trials_each_frame_list: 
        m_str: string with the tmux session name's assigned animal
    """    
    categorical_ego = False
    ego_drop = 160
    is_odd = True if int(tmux_session_name) % 2 != 0 else False
    mouse_folder = f"YC0{tmux_session_name}"
    print(f"is_odd {is_odd} mouse_folder {mouse_folder}")
    mouse_and_date_list = [f"{mouse_folder}_{date}" for date in os.listdir(social_foraging_data_path+ mouse_folder) if "20" in date] #"YC069_20240601" #"YC069_20240601"
    is_m1 = is_odd  # odd = m1, even = m2, we always set the odd number
    print(mouse_and_date_list)
    m_str = mouse_and_date_list[0].split("_")[0]
    pickle_file_name = f"{output_dir}{m_str}_data_each_session.pkl"
    neural_data_list = []
    conditions_dict_list = []
    indices_of_trials_each_frame_list = []
    phase_str = ""
    # odd = m1, even = m2, we always set the odd number
    # of animal name as shaved mouse,
    # The shaved mouse in the video is always the m1
    for mouse_and_date in mouse_and_date_list:
        print(mouse_and_date)
        m,d = mouse_and_date.split("_")[0], mouse_and_date.split("_")[1]
        path_to_mouse_and_date = f"{social_foraging_data_path}{m}/{phase_str}{d}/"
        landmarks_path = path_to_mouse_and_date + [x for x in os.listdir(path_to_mouse_and_date) if "landmks.json" in x or "landmarks.json" in x][0]
        SLEAP_file_path = path_to_mouse_and_date + [x for x in os.listdir(path_to_mouse_and_date) \
                if "avi.mat" in x and "old" not in x][0]
        
        stable_path = path_to_mouse_and_date + [x for x in os.listdir(path_to_mouse_and_date) if "stable.mat.csv" in x][0]
        neural_data_path = path_to_mouse_and_date + [x for x in os.listdir(path_to_mouse_and_date) if "GC6_25ms.mat.csv" in x][0]
        print(SLEAP_file_path)
        
        #SLEAP_file_path = '/home/ross/Documents/lab_projects/data/neural/YC074/phase4a/20240806/YC073YC074phase4-08062024103305.avi.mat'
        m_id = 1.0 if is_m1 else 2.0
        SLEAP_data_rotated_all, indices_of_trials_each_frame, conditions_dict, \
            self_waiting_in_reward_zone_each_trial, other_waiting_in_reward_zone_each_trial = \
                cebra_analysis_helpers.get_rotated_all_frames(SLEAP_file_path, stable_path, 
                                                                landmarks_path, is_m1 = is_m1,
                                                                ego_drop=ego_drop,
                                                                categorical_ego=categorical_ego)
        # get spike data and get rid of na/align with the behavior
        neural_data = pd.read_csv(neural_data_path, header = None)
        neural_data = neural_data.to_numpy().T
        print(SLEAP_data_rotated_all.shape, neural_data.shape)
        # trim from the end of the spike data as much as needed to align with the SLEAP data
        if len(SLEAP_data_rotated_all) < len(neural_data):
            print("neural trim from end")
            neural_data = neural_data[:SLEAP_data_rotated_all.shape[0],:]
        else:
            print("behavior trim from end")
            SLEAP_data_rotated_all = SLEAP_data_rotated_all[:len(neural_data),:,:,:]
            indices_of_trials_each_frame = indices_of_trials_each_frame[:len(neural_data)]
            conditions_dict = {key:value[:len(neural_data)] for key,value in conditions_dict.items()}

        print(SLEAP_data_rotated_all.shape, neural_data.shape)
        indices_to_remove = np.unique(np.where(np.isnan(neural_data))[0])
        # chop off the nan rows
        neural_data = np.delete(neural_data, indices_to_remove, axis = 0)
        SLEAP_data_rotated_all = np.delete(SLEAP_data_rotated_all, indices_to_remove, axis = 0)
        indices_of_trials_each_frame = np.delete(indices_of_trials_each_frame, indices_to_remove, axis = 0)
        conditions_dict = {key:np.delete(value, indices_to_remove, axis = 0) for key,value in conditions_dict.items()}
        neural_data_list.append(neural_data)
        conditions_dict_list.append(conditions_dict)
        indices_of_trials_each_frame_list.append(indices_of_trials_each_frame)
    pickle_dict = {"mouse_and_date_list": mouse_and_date_list,
                "neural_data_list":neural_data_list,
                "conditions_dict_list":conditions_dict_list,
                "indices_of_trials_each_frame_list": indices_of_trials_each_frame_list}
    # Save embeddings in current folder
    with open(pickle_file_name, 'wb') as f:
        pickle.dump(pickle_dict, f)
    f.close()
    return mouse_and_date_list, neural_data_list, conditions_dict_list, indices_of_trials_each_frame_list, m_str


def run_single_grid(output_dir,mouse_and_date_list, neural_data_list, conditions_dict_list, indices_of_trials_each_frame_list,
                    m_str, batch_size,time_offset,temperature_mode,temperature,max_iter,num_hidden_units,output_dims,
                    lr,behavior,approach, conditional, test_size, tmux_session_name, device_id):
    """run a single grid of the gridsearch by training the model on training set
    and getting embeddings for train and validation set, and shift the behavior if 
    we are in the control mode

    Args:
        output_dir (str): where to output the organzied data 
        mouse_and_date_list: list of strings for all of the sessions for this animal 
        neural_data_list: list of cleaned up numpy arrays with neural data for each session
        conditions_dict_list (list of conditions): list of dicts for each session with each dict having lists of different behavioral variables we could use in CEBRA
        indices_of_trials_each_frame_list (list of list of booleans 0/1): for each session, we need to know which indices are trials
        m_str (str): animal name
        batch_size (int): batch size for training CEBRA
        time_offset (int): cebra parameter (look it up on cebra docs)
        temperature_mode (str): cebra parameter (look it up on cebra docs)
        temperature (float): cebra parameter (look it up on cebra docs)
        max_iter (int): cebra parameter (look it up on cebra docs)
        num_hidden_units (int): cebra parameter (look it up on cebra docs)
        output_dims (int): CEBRA embedding dimension
        lr (float): cebra learning rate
        behavior (str): the behavior we are using for CEBRA-behavior (change what goes into the model depending on this string)
        approach (str): how we are doing the training and whether we are in a control condition (manipulate the training/behavior based on the string contents) 
        conditional (str): cebra parameter (look it up on cebra docs)
        test_size (int in range [0,1]): size of validation set compared to training
        tmux_session_name (str): what animal we are analyzing, for parallelizing across tmux sessions
        device_id (int): specifies the gpu device
    """
    save_info_str = f"{m_str}_bs{batch_size}_tmp_{temperature}_Miter{max_iter}_h{num_hidden_units}_lr{lr}"
    dir_path = f"{output_dir}demo_{save_info_str}/"
    behavior_approach_path = f"{dir_path}{behavior}_{approach}_tmux{tmux_session_name}/"
    print(f"starting {behavior_approach_path}")
    # if the directory does not exist, only then do we want to proceed
    if os.path.isdir(behavior_approach_path):
        print(f"already exists at {behavior_approach_path}")
        return 
    if not os.path.isdir(dir_path):
        os.mkdir(dir_path[:-1])
    if not os.path.isdir(behavior_approach_path):
        os.mkdir(behavior_approach_path)
    behavior_probe = "self_other_distance" if behavior == "distance" else "ego_angle_from_self_each_frame"
    include_frames_behavior_mode_list = [] 
    cropped_indices_of_trials_each_frame_list = []
    for i,this_conditions_dict in enumerate(conditions_dict_list):
        include_frames_behavior_mode = this_conditions_dict["either_mouse_is_in_rzs_radius_each_frame"] == 0
        if behavior == "angle":
            include_frames_behavior_mode = np.logical_and(include_frames_behavior_mode, ~np.isnan(this_conditions_dict["ego_angle_from_self_each_frame"]))
        include_frames_behavior_mode_list.append(include_frames_behavior_mode)
    cropped_indices_of_trials_each_frame_list = [indices_of_trials_each_frame_list[i][include_frames_behavior_mode_list[i]] for i in range(len(conditions_dict_list))]
    behavior_labels_behavior_mode_list = [this_conditions_dict[behavior_probe][include_frames_behavior_mode_list[i]] \
                            for i,this_conditions_dict in enumerate(conditions_dict_list)]


    if "shift" in approach:
        for i in range(len(behavior_labels_behavior_mode_list)):
            before_behavior_labels_behavior_mode = behavior_labels_behavior_mode_list[i]
            behavior_labels_behavior_mode_list[i] = np.roll(behavior_labels_behavior_mode_list[i], shift = int(len(behavior_labels_behavior_mode_list[i]) *0.5))

    neural_data_behavior_mode_list = [this_neural_data[include_frames_behavior_mode_list[i],:] for i,this_neural_data in enumerate(neural_data_list)]
    # separate those cropped lists to train and test
    from sklearn.model_selection import train_test_split
    train_indices_list = []
    valid_indices_list = []
    unique_trial_ids_list = []

    # by trial
    if "ByTrial" in approach:
        for sess_id, trial_ids in enumerate(cropped_indices_of_trials_each_frame_list):
            unique_trial_ids = np.unique(trial_ids)
            train_trials,valid_trials = train_test_split(unique_trial_ids, test_size=test_size)
            train_indices = []
            for train_trial in train_trials:
                train_indices += np.where(trial_ids == train_trial)[0].tolist()
            valid_indices = []
            for valid_trial in valid_trials:
                valid_indices += np.where(trial_ids == valid_trial)[0].tolist()
            train_indices_list.append(train_indices)
            valid_indices_list.append(valid_indices)

    train_cropped_indices_of_trials_each_frame_list = \
    [cropped_indices[train_indices] for train_indices,cropped_indices in zip(train_indices_list, cropped_indices_of_trials_each_frame_list)]
    valid_cropped_indices_of_trials_each_frame_list = \
    [cropped_indices[valid_indices] for valid_indices,cropped_indices in zip(valid_indices_list, cropped_indices_of_trials_each_frame_list)]
    train_behavior_labels_behavior_mode_list = \
    [behavior_labels[train_indices] for train_indices,behavior_labels in zip(train_indices_list, behavior_labels_behavior_mode_list)]
    valid_behavior_labels_behavior_mode_list = \
    [behavior_labels[valid_indices] for valid_indices,behavior_labels in zip(valid_indices_list, behavior_labels_behavior_mode_list)]
    train_neural_data_behavior_mode_list = \
    [this_neural_data[train_indices] for train_indices,this_neural_data in zip(train_indices_list, neural_data_behavior_mode_list)]
    valid_neural_data_behavior_mode_list = \
    [this_neural_data[valid_indices] for valid_indices,this_neural_data in zip(valid_indices_list, neural_data_behavior_mode_list)]
    multi_embeddings = dict()
    # Multisession training
    multi_cebra_model = CEBRA(model_architecture='offset10-model',
                    batch_size=batch_size,
                    learning_rate=lr,
                    temperature=temperature,
                    temperature_mode=temperature_mode,
                    output_dimension=output_dims,
                    max_iterations=max_iter,
                    distance='cosine',
                    conditional=conditional,
                    device=f'cuda:{device_id}',
                    verbose=True,
                    time_offsets=time_offset,
                    num_hidden_units=num_hidden_units)
    # Provide a list of data, i.e. datas = [data_a, data_b, ...]
    multi_cebra_model.fit(train_neural_data_behavior_mode_list, train_behavior_labels_behavior_mode_list) #, behavior_labels_behavior_mode_list)
    model_dump_file = f"{behavior_approach_path}multi_cebra_model_tmux{tmux_session_name}.pkl"
    # Save embeddings in current folder
    print("current wd", os.getcwd())
    ax = cebra.plot_loss(multi_cebra_model)
    loss_save = f"{behavior_approach_path}LOSS_tmux{tmux_session_name}.png"
    plt.savefig(loss_save)
    # get train embeddings
    train_multi_embeddings = []
    # Transform each session with the right model, by providing the corresponding session ID
    for i, X in enumerate(train_neural_data_behavior_mode_list):
        train_multi_embeddings.append(multi_cebra_model.transform(X, session_id=i))
        # Save embeddings in current folder
        # get validation embeddings
    valid_multi_embeddings = []
        # Transform each session with the right model, by providing the corresponding session ID
    for i, X in enumerate(valid_neural_data_behavior_mode_list):
        valid_multi_embeddings.append(multi_cebra_model.transform(X, session_id=i))
    # Save embeddings in current folder
    train_valid_dict = {"train_multi_embeddings": train_multi_embeddings,
                    "valid_multi_embeddings": valid_multi_embeddings,
                    "train_trials": train_trials,
                    "valid_trials": valid_trials,
                    "train_indices_list": train_indices_list,
                    "valid_indices_list": valid_indices_list,
                    "cropped_indices_of_trials_each_frame_list": cropped_indices_of_trials_each_frame_list, 
                    "behavior_labels_behavior_mode_list": behavior_labels_behavior_mode_list,
                    "neural_data_behavior_mode_list":
                        neural_data_behavior_mode_list,
                    "behavior": behavior,
                    "approach": approach,
                    "mouse_and_date_list": mouse_and_date_list
    }
    dump_file = f"{behavior_approach_path}train_valid_dict_tmux{tmux_session_name}.pkl"

    with open(dump_file, 'wb') as f:
        pickle.dump(train_valid_dict, f)