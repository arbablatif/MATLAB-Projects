% Code to extract the features of the Test data
clear all; close all; clc;
dataset_dir = '.\Data_Train\';        % Folder where the dataset is located
result_dir='.\Result\';           % Folder to save the images if save =1
feature_dir='.\Features\';        % Folder to save the mat files with features

save_im=1; % Save the Images with HL and LP 



%% Nothing to change
dataset_dir=dir(dataset_dir);
ndata=length(dataset_dir);

for jj=1:ndata
    %% Reading Images
    imagefiles = dir([dataset_dir(jj).folder,'\',dataset_dir(jj).name,'\*.bmp']);
    Data=[];
    nfiles = length(imagefiles);    % Number of files found
    for ii=1:nfiles
        close all
        currentfilename = [imagefiles(ii).folder,'\',imagefiles(ii).name];
        currentimage = imread(currentfilename);
        images = currentimage;
        images_bw=rgb2gray(currentimage);
        img=images_bw;
        run lp_detection.m
        clearvars -except dataset_dir result_dir  feature_dir ndata jj ii ...
            Data imagefiles nfiles save_im lp_e cen_hl c_hl hl_cand orig_img
        run hl_detection.m
        
%         if save_im==1
%             newdir=[result_dir,dataset_dir(dd).name];
%             if ~exist(newdir,'dir')
%                 mkdir (newdir)
%             end
%             
%             FolderName = [result_dir,dataset_dir(dd).name,'\'];
%             run sav.m
%         end
        
        clearvars -except dataset_dir result_dir feature_dir ndata jj ii ...
            Data imagefiles nfiles save_im orig_img lp_e hl_e fin
        run feature_select.m
        Data{ii,1}= feat;
        Data{ii,2}=imagefiles(ii).name;
        clearvars -except dataset_dir result_dir feature_dir ndata jj ii ...
            Data imagefiles nfiles save_im
    end
    display(dataset_dir(jj).name)
    data_var=[feature_dir,dataset_dir(jj).name,'.mat'];
%     save(data_var,'Data');
end