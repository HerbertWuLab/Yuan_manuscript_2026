function role = get_role_demo(cur_animal)
if ismember(cur_animal,{'YC069','YC071','YC073','YC075','YC091','YC115'})
    role = 'follower';
elseif ismember(cur_animal,{'YC070','YC072','YC074','YC076','YC111','YC116'})
    role = 'leader';
end