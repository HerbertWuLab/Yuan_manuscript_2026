function id = get_mouse_id(cur_fd)
animal_str_idx = strfind(cur_fd,'YC');
animal_num = str2double(cur_fd(animal_str_idx+2:animal_str_idx+4));
if mod(animal_num,2)==1 % odd numbered animal is m1
    id = 'm1';
elseif mod(animal_num,2)==0 % even numbered animal is m2
    id = 'm2';
else
    disp('Error!')
end