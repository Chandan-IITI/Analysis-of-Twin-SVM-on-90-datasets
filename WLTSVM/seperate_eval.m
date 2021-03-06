
function [test_acc] = seperate_eval(name)

addpath([pwd '\wltsvm']);
%%% datasets can be downloaded from "http://persoal.citius.usc.es/manuel.fernandez.delgado/papers/jmlr/data.tar.gz"
datapath = 'provide the path of your dataset';

train = load ([datapath name '\' name '_train_R.dat']);% for datasets where training-testing partition is available, paramter tuning is based on this file.
index_tune = importdata ([datapath name '\conxuntos.dat']);% for datasets where training-testing partition is available, paramter tuning is based on this file.
test_eval = load ([datapath name '\' name '_test_R.dat']);% for datasets where training-testing partition is available, paramter tuning is based on this file.

%%% Checking whether any index valu is zero or not if zero then increase all index by 1
if length(find(index_tune == 0))>0
    index_tune = index_tune + 1;
end

%%% Remove NaN and store in cell
 for k=1:size(index_tune,1)
  index_sep{k}=index_tune(k,~isnan(index_tune(k,:)));
 end

%%% To Evaluate
test_data = test_eval(:,2:end-1);
test_label = test_eval(:,end);
test_lab = test_label;  %%% Just replica for further modifying the class label

%%% To Tune
dataX=train(:,2:end-1);
dataY=train(:,end);
dataYY = dataY; %%% Just replica for further modifying the class label

%%%%%% Normalization start
% do normalization for each feature
mean_X=mean(dataX,1);
dataX=dataX-repmat(mean_X,size(dataX,1),1);
norm_X=sum(dataX.^2,1);
norm_X=sqrt(norm_X);
norm_eval = norm_X; %%% Just save fornormalizing the evaluation data
norm_X=repmat(norm_X,size(dataX,1),1);
dataX=dataX./norm_X;

%%%% Normalize the evaluation data
norm_ev = repmat(norm_eval,size(test_data,1),1);
test_data=test_data./norm_ev;
%%%% End of normalization of evaluation data
%%%% End of Normalization %%%%

%%%% Modifying the class label as per TBSVM and chcking whether binaryvclass data or not
unique_classes = unique(dataYY);
if (numel(unique(unique_classes))>2)
    error('Data belongs to multi-class, please provide binary class data');
else
    dataY(dataYY==unique_classes(1),:)=1;
    dataY(dataYY==unique_classes(2),:)=-1;
    
    %%% For valuation on test data
    test_label(test_lab==unique_classes(1),:)=1;
    test_label(test_lab==unique_classes(2),:)=-1;
    
end

%%% Seperation of data
%%% To Tune
trainX=dataX(index_sep{1},:); 
trainY=dataY(index_sep{1},:);
testX=dataX(index_sep{2},:);
testY=dataY(index_sep{2},:);

DataTrain.A = trainX(trainY==1,:);
DataTrain.B = trainX(trainY==-1,:);

c1 = [2^-5,2^-4,2^-3,2^-2,2^-1,2^0,2^1,2^2,2^3,2^4,2^5];
%c2 = [2^-5,2^-4,2^-3,2^-2,2^-1,2^0,2^1,2^2,2^3,2^4,2^5];
c3 = [2^-5,2^-4,2^-3,2^-2,2^-1,2^0,2^1,2^2,2^3,2^4,2^5]; %%% Eps1
%c4 = [2^-5,2^-4,2^-3,2^-2,2^-1,2^0,2^1,2^2,2^3,2^4,2^5]; %%% Eps2
% c5 = scale_range_rbf(dataX);
c5 = [2^-10,2^-9,2^-8,2^-7,2^-6,2^-5,2^-4,2^-3,2^-2,2^-1,2^0,2^1,2^2,2^3,2^4,2^5,2^6,2^7,2^8,2^9,2^10];

MAX_acc = 0; Resultall = []; count = 0;

for i=1:length(c1)
%     for j=1:length(c2)
        for k=1:length(c3)
%             for l=1:length(c4)
                for m=1:length(c5)
                    
                    count = count +1  %%%% Just displaying the number of iteration
                    
                    FunPara.c1=c1(i);
%                     FunPara.c2=c2(j); 
                    FunPara.c2=c1(i);
                    FunPara.c3=c3(k);
%                     FunPara.c4=c4(l);
                    FunPara.c4=c3(k);
                    FunPara.kerfPara.type = 'rbf';
                    FunPara.kerfPara.pars = c5(m);
                    
                    Predict_Y =WLTSVM(testX,DataTrain,FunPara);
                    
                    test_accuracy=length(find(Predict_Y==testY))/numel(testY);                    
                    
                    %%%% Save only optimal parameter with testing accuracy
                    if test_accuracy>MAX_acc; % paramater tuning: we prefer the parameter which lead to better accuracy on the test data. 
  MAX_acc=test_accuracy;
  OptPara.c1=FunPara.c1; OptPara.c2=FunPara.c2; OptPara.c3=FunPara.c3; OptPara.c4=FunPara.c4;
  OptPara.kerfPara.type = FunPara.kerfPara.type; OptPara.kerfPara.pars = FunPara.kerfPara.pars;                
                    end                   
clear Predict_Y;
                end
%             end
        end
%     end
end

%%%% Training and valuation with optimal parameter value
clear DataTrain;

DataTrain.A = dataX(dataY==1,:);
DataTrain.B = dataX(dataY==-1,:);
% DataTrain.A = [trainX(trainY==1,:);testX(testY==1,:)];
% DataTrain.B = [trainX(trainY==-1,:);testX(testY==-1,:)];
Predict_Y =WLTSVM(test_data,DataTrain,OptPara);
test_acc = length(find(Predict_Y==test_label))/numel(test_label)
OptPara.test_acc = test_acc*100;

filename = ['Res_' name '.mat'];
save (filename, 'OptPara');
end
