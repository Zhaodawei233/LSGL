warning off %#ok<WNOFF>
clear;clc
addpath(genpath('.'));
starttime = datestr(now,0);
load('data\arts.mat')
% test_data=test_train;
[optmParameter,modelparameter] =  initialization;

if exist('train_targets','var')==1&&exist('test_targets','var')==1
    test_target=test_targets';
    train_target=train_targets';
    clear train_targets test_targets
end

%% cross validation
if exist('train_data','var')==1
    data=[train_data;test_data];
    target=[train_target,test_target];
    clear train_data test_data train_target test_target
end
data     = double(data);
target(target==-1)=0;
num_data = size(data,1);

if modelparameter.L2Norm == 1
    temp_data = normalization(data, 'l2', 1);
else
    temp_data = data;
end
clear data  
randorder = randperm(num_data);
Result_LSGL  = zeros(5,modelparameter.cv_num);
for i = 1:modelparameter.repetitions   
    for j = 1:modelparameter.cv_num
            fprintf('- Repetition - %d/%d,  Cross Validation - %d/%d\n', i, modelparameter.repetitions, j, modelparameter.cv_num);

           %% the training and test parts are generated by fixed spliting with the given random order
            [cv_train_data,cv_train_target,cv_test_data,cv_test_target ] = generateCVSet( temp_data,target',randorder,j,modelparameter.cv_num );
            cv_train_target=cv_train_target';
            cv_test_target=cv_test_target';

           %% Tune the parametes
            if optmParameter.searchPara == 1
                if (optmParameter.tuneParaOneTime == 1) && (exist('BestResult','var')==0)
                    fprintf('\n-  parameterization for LSGL by cross validation on the training data');
                    [optmParameter, BestResult ] = LSGL_grid_search( cv_train_data, cv_train_target, optmParameter);
                elseif (optmParameter.tuneParaOneTime == 0)
                    fprintf('\n-  parameterization for LSGL by cross validation on the training data');
                    [optmParameter, BestResult ] = LSGL_grid_search( cv_train_data, cv_train_target, optmParameter);
                end
            end
           %% If we don't search the parameters, we will run LSGL with the fixed parametrs
            [model_LSGL]  = LSGL( cv_train_data, cv_train_target',optmParameter);

            Outputs=cv_test_data*model_LSGL.W;
            Outputs=Outputs';
            Pre_Labels=sign(Outputs-0.5);
            Pre_Labels(Pre_Labels==-1)=0;
            Result_LSGL(:,j) = EvaluationAll(Pre_Labels,Outputs,cv_test_target);
    end
end
%% the average results of LSGL
Avg_Result = zeros(5,2);
Avg_Result(:,1)=mean(Result_LSGL,2);
Avg_Result(:,2)=std(Result_LSGL,1,2);
fprintf('\nResults of LSGL\n');
PrintResults(Avg_Result);
rmpath(genpath('.'));
endtime = datestr(now,0);
beep;