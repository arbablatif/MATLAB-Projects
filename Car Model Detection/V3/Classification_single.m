%%  File to calculate the car and model
%       set the percentage for Training and Testing
%
%   1) Extract the features, run the following
%                 FS_train.m
%
%   2) Move Target car to the specific folder and run

clear all;  close all;  clc;
Target_car='.\Features\Target\';   % Target car feature directory
Other_car='.\Features\';   % Target car feature directory
Folder='.\Data_Train';
TC_train=70;      % Percent Sample of the Target car for training
OC_Test=100;       % Percent sample of the other cars for testing

%% Nothing to Change


oc_nu=4;

matset = dir([Target_car,'\*.mat']);
ndata=length(matset);
Fin=[];
fin_test=[];

target_num=[];
for dd=1:ndata
    currentfilename = [matset(dd).folder,'\',matset(dd).name];
    Fil=open(currentfilename);
    Target_name=matset(dd).name(4:end-4);
    Data=cell2mat(Fil.Data2(:,1)')';
    tr_sa=round(TC_train*size(Data,1)/100);
    rand_data=randi(tr_sa,size(Data,1),1);
    tr_data=Data(rand_data,:);
    Name=Fil.Data2(rand_data,2);
    new=str2double(matset(dd).name(1:3))*ones(size(tr_data,1),1);
    target_num=[target_num; str2double(matset(dd).name(1:3))];
    Fin=[Fin; new tr_data];
    rand_data=randi(size(Data,1)-tr_sa,size(Data,1),1);
    te_data=Data(rand_data,:);
    new=str2double(matset(dd).name(1:3))*ones(size(te_data,1),1);
    
end


matset = dir([Other_car,'\*.mat']);
ndata=length(matset);
for dd=1:ndata
    currentfilename = [matset(dd).folder,'\',matset(dd).name];
    if length(matset(dd).name)<8
        continue   % skip files without a proper name
    else
        Fil=open(currentfilename);
        Data_temp=cell2mat(Fil.Data2(:,1)')';
        rand_data=randi(size(Data_temp,1),oc_nu,1);
        Name=[Name;Fil.Data2(rand_data,2)];
        Data=Data_temp(rand_data,:);
        new=str2double(matset(dd).name(1:3))*ones(size(Data,1),1);
        Fin=[Fin; new Data];
    end
end

Bad_F=any(Fin(:,2:end),2);
Name_tr_bad=Name(~Bad_F,:);
Name_tr=Name(Bad_F,:);
Fin_Temp=Fin(Bad_F,:);
res=Fin_Temp(:,1);
pre=Fin_Temp(:,2:end);

[r,c]=find(res==target_num');
d=zeros(size(res,1),1);
d(r,1)=1;
res(:,1)=d(:,1);
%% knn Classifier
knn_3_mod=fitcknn(pre,res,'NumNeighbors',3,'Distance','euclidean');
knn_5_mod=fitcknn(pre,res,'NumNeighbors',5,'Distance','euclidean');
knn_7_mod=fitcknn(pre,res,'NumNeighbors',7,'Distance','euclidean');
CVMdl_knn_3 = crossval(knn_3_mod,'KFold',10);
kloss_knn_3 = kfoldLoss(CVMdl_knn_3);
CVMdl_knn_5 = crossval(knn_5_mod,'KFold',10);
kloss_knn_5 = kfoldLoss(CVMdl_knn_5);
CVMdl_knn_7 = crossval(knn_7_mod,'KFold',10);
kloss_knn_7 = kfoldLoss(CVMdl_knn_7);
%% SVM Classifier
svm_mod=fitcsvm(pre,res,'Standardize',true,'KernelFunction','RBF','KernelScale','auto');
CVMdl_svm = crossval(svm_mod,'KFold',10);
kloss_svm = kfoldLoss(CVMdl_svm);
%% DT Classifier
dt_mod=fitctree(pre,res);
CVMdl_dt = crossval(dt_mod,'KFold',10);
kloss_dt = kfoldLoss(CVMdl_dt);
%%
ddd=1;
while ddd==1
    clc;
    close all;
    ext='*.jpg' ;
    save_im=1;
    [filename, path] = uigetfile([Folder '\' ext]) ;
    imageData = imread(fullfile(path, filename));
%     images_bw=rgb2gray(imageData);
    img=imageData;
    run lp_detection.m
    run hl_detection.m
    run feature_select.m
    test=feat';
    
    
    %% Estimation
    pr_k_3=predict(knn_3_mod,test);
    pr_k_5=predict(knn_5_mod,test);
    pr_k_7=predict(knn_7_mod,test);
    
    Knn_comb=pr_k_3+pr_k_5+pr_k_7;
    Knn_comb(Knn_comb<2)=0;
    Knn_comb(Knn_comb>1)=1;
    
    pr_svm=predict(svm_mod,test);
    pr_dt=predict(dt_mod,test);
    
    %% Final Decision
    final=1/3*(Knn_comb+ pr_svm +pr_dt);
    final(final>0.5)=1;
    final(final<0.5)=-1;
    fprintf('|--------------------------------------------------------|\n');
    if final==1
        title('Image contain the target car')
        fprintf('The car model is %s. \n',Target_name);
    else
        title('Image does not contain the target car')
        fprintf('The car model is not %s. \n',Target_name);
    end
    fprintf('|--------------------------------------------------------|\n');
    ddd=input('If you want to continue and check another car, enter 1.\n');
end

