## MACHINE LEARNING 1, 9. JAN. 2017
## ASSIGNMENT 8
## 
## Andres Fernandez Rodriguez, 5692442
## 
## The assignment has been done with Octave 3.8. In order to run it,
## place the script "fernandez_exercise8.m" and the file "comp_testX.dat" in the same directory, and run
## 
## octave fernandez_exercise8.m
## 
## The program will then output the predictions into comp_testY.dat



################################################################################
### 1) MAPPING: the different functions in this section correspond to
### different basis functions. The approach is to build design
### matrices with one column per features. This isn't the most
### efficient way, but it is simple and affordable for 250 training datapoints
################################################################################

## this is the simplest transfer function: bias+original components
function result = mapSamplesID(x)
  bias = ones(rows(x), 1);
  result = [bias, x];
endfunction

## this model contains bias+originals+all 2nd order interaction features
function result = mapSamples2nd(x)
  bias = ones(rows(x), 1);
  result = [bias, x, ... 
           x(:,1).*x(:,1), x(:,1).*x(:,2), x(:,1).*x(:,2), ...
            x(:,1).*x(:,3), x(:,1).*x(:,4), x(:,1).*x(:,5), ...
           x(:,2).*x(:,2), x(:,2).*x(:,3), x(:,2).*x(:,4), x(:,2).*x(:,5), ...
           x(:,3).*x(:,3), x(:,3).*x(:,4), x(:,3).*x(:,5), ...
           x(:,4).*x(:,4), x(:,4).*x(:,5), ...
           x(:,5).*x(:,5)];
endfunction

## this model is like mapSamples2nd+ some 3rd order interaction features (overfits)
function result = mapSamples3rd(x)
  bias = ones(rows(x), 1);
  result = [bias, x, ...
            x(:,1).*x(:,1), x(:,1).*x(:,2), x(:,1).*x(:,2), ...
            x(:,1).*x(:,3), x(:,1).*x(:,4), x(:,1).*x(:,5), ...
           x(:,2).*x(:,2), x(:,2).*x(:,3), x(:,2).*x(:,4), x(:,2).*x(:,5), ...
           x(:,3).*x(:,3), x(:,3).*x(:,4), x(:,3).*x(:,5), ...
           x(:,4).*x(:,4), x(:,4).*x(:,5), x(:,5).*x(:,5), ....
           x(:,1).*x(:,1).*x(:,1), x(:,2).*x(:,2).*x(:,2),...
           x(:,3).*x(:,3).*x(:,3), x(:,4).*x(:,4).*x(:,4), x(:,5).*x(:,5).*x(:,5), ...
           x(:,1).*x(:,1).*x(:,2), x(:,1).*x(:,2).*x(:,2),...
           x(:,1).*x(:,2).*x(:,3), x(:,1).*x(:,3).*x(:,3), x(:,1).*x(:,3).*x(:,4), ...
           x(:,1).*x(:,4).*x(:,4), x(:,1).*x(:,4).*x(:,5),...
           x(:,1).*x(:,5).*x(:,5), x(:,2).*x(:,2).*x(:,3), x(:,2).*x(:,3).*x(:,3), ...
           x(:,2).*x(:,3).*x(:,4), x(:,2).*x(:,4).*x(:,4),...
           x(:,2).*x(:,4).*x(:,5), x(:,2).*x(:,5).*x(:,5), x(:,3).*x(:,3).*x(:,4), ...
           x(:,3).*x(:,4).*x(:,4), x(:,3).*x(:,4).*x(:,5),...
           x(:,3).*x(:,5).*x(:,5), x(:,4).*x(:,4).*x(:,5), x(:,4).*x(:,5).*x(:,5)];
endfunction


# pick the 2nd-order interaction matrix (had consistently the best CV
# score) and put a tanh layer on the top of it (also overfits)
function result = mapSamples2ndTanh(x, a, b)
  expand = mapSamples2nd(x);
  result = [expand, a*x-b];
endfunction


################################################################################
### 2) LEARNING FROM TRAINING SET: this is performed simply by
### computing the optimal weights from the normal equations.
## as we know, the formula is:
## w = inv(X'*X) * X' * y
## which, performing the SVD of x, is equivalent to the following:
## w = inv(V*Sigma*U' * U*Sigma*V') * V*Sigma*U' * y
##   = inv(V*Sigma*Sigma*V') * V*Sigma*U' * y
##   = V*Sigma^(-2)*V'*V*Sigma*U' * y
##   = V* Sigma^(-2)*Sigma*U'*y
##   = V*Sigma^(-1)*U'*y
################################################################################


function w = learnWeights(design_mat, train_y)
  [U, S, V] = svd(design_mat, true);
  w = V*pinv(S)*U'*train_y;
endfunction



################################################################################
### 3) PREDICTING, COMPUTING COST
################################################################################

function result = predict(design_mat, weights)
  result = design_mat*weights; # linear combination of inputs and weights
endfunction

## the formula given in the sheet
function result = score_function(design_mat, dataY, weights)
  predictions = predict(design_mat, weights);
  mu = sum(predictions)/length(predictions);
  err_y = predictions-dataY;
  err_y = err_y' * err_y;
  err_mu = predictions-mu;
  err_mu = err_mu' * err_mu;
  result = 1 - (err_y/err_mu);
endfunction






################################################################################
### 4) RUN IT!
################################################################################

global ALPHA = 0.1;
global BETA = 0;


## load training data
x = load("comp_trainX.dat");
y = load("comp_trainY.dat");


## shuffle training data
function result = shuffleMatrix(mat, perm)
  result = cell2mat(arrayfun(@(n) mat(:,n), perm, "UniformOutput",false));
endfunction
perm = randperm(rows(y));
xshuf = shuffleMatrix(x', perm)';
yshuf = shuffleMatrix(y', perm)';


## split into training (70%) and CV (30%)
train_size = round(length(y)*0.7);
x_train = xshuf(1:train_size,:);
y_train = yshuf(1:train_size,:);
x_cv = xshuf((train_size+1):end, :);
y_cv = yshuf((train_size+1):end, :);




################################################################################
### 3) TRAINING, CROSS-VALIDATING:
### conclusion of this section: @mapSamples2nd performs consistently
### better than any other model (all of them without regularization)
## IMPORTANT: this section is part of the "search for a good model", and can 
## be commented out without affecting the predictions for the test set
################################################################################
function score = train_and_cv(mapFn, trainx, trainy, cvx, cvy)
  w = learnWeights(mapFn(trainx), trainy);
  score = score_function(mapFn(cvx), cvy, w);
  fprintf("\nthe R2 score on the CV set for the %s hypothesis was %f\n", func2str(mapFn), score);
endfunction

train_and_cv(@mapSamplesID, x_train, y_train, x_cv, y_cv);
train_and_cv(@mapSamples2nd, x_train, y_train, x_cv, y_cv);
train_and_cv(@mapSamples3rd, x_train, y_train, x_cv, y_cv);

function score = train_and_cv_tanh(trainx, trainy, cvx, cvy, a, b)
  w = learnWeights(mapSamples2ndTanh(trainx,a,b), trainy);
  score = score_function(mapSamples2ndTanh(cvx,a,b), cvy, w);
  fprintf("\nthe R2 score on the CV set for the mapSamples2ndTanh hypothesis with alpha=%f and beta=%f was %f\n", a,b, score);
endfunction


for i=[-1, -0.3, -0.1, 0]
  clear ALPHA;
  global ALPHA = i;
  for j=[-0.2, 0, 0-2]
    clear BETA;
    global BETA = j;
    train_and_cv_tanh(x_train, y_train, x_cv, y_cv, i, j);
  endfor
endfor




################################################################################
### 4) THE MAIN ROUTINE
################################################################################

# as a result from the tryouts of section 3, the weights will be
# learned from the training set using the @mapSamples2nd model:
trainX = load("comp_trainX.dat");
trainY = load("comp_trainY.dat");
weights = learnWeights(mapSamples2nd(trainX), trainY);

# now the test data can be loaded, and the predictions saved to comp_TestY.dat:
testX = load("comp_testX.dat");
predictions = predict(mapSamples2nd(testX), weights);
save "comp_testY.dat" predictions;

fprintf("\nregression finished! you can find the predictions in the...
comp_testY.dat file\n");
