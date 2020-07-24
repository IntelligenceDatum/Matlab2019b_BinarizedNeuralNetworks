classdef BinarizedTransposedConvolution2DGPUStrategy < nnet.internal.cnn.layer.util.ExecutionStrategy
    % TransposedConvolution2DGPUStrategy   
    %    Execution strategy for running the transposed convolution on the
    %    GPU.
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    
    methods
        function [Z, memory] = forward(~, X, ...
                weights, bias, ...
                topPad, leftPad, bottomPad, rightPad, ...
                verticalStride, horizontalStride, ...
                verticalOutputSizeOffset, horizontalOutputSizeOffset)  
            
            paddingSize = [topPad bottomPad leftPad rightPad];
            
            weights= sign(weights);  %%%%%%% %%%%%%% %%%%%%%
            weights(weights==0)=1; %%%%%%% %%%%%%% %%%%%%%
            
            if iPaddingIsSymmetric(paddingSize)
                outputSize = ...
                    BinarizedTransposedConvolution2D.outputSize(...
                    X, weights, ...
                    topPad, leftPad, bottomPad, rightPad, ...   
                    verticalStride, horizontalStride, ...
                    verticalOutputSizeOffset, horizontalOutputSizeOffset);
                Z = nnet.internal.cnngpu.convolveBackwardData2DCore(...
                    outputSize, weights, X, ...
                    topPad, leftPad, bottomPad, rightPad, ...
                    verticalStride, horizontalStride);
            else
                outputSize = ...
                    BinarizedTransposedConvolution2D.outputSize(...
                    X, weights, ...
                    0, 0, 0, 0, ...   
                    verticalStride, horizontalStride, ...
                    verticalOutputSizeOffset, horizontalOutputSizeOffset);
                Z = nnet.internal.cnngpu.convolveBackwardData2DCore(...
                    outputSize, weights, X, ...
                    0, 0, 0, 0, ...
                    verticalStride, horizontalStride);
                Z = iUnpadArray(Z, paddingSize);
            end
            
            % add bias
            Z = arrayfun(@plus, Z, bias);   
            
            memory = [];
        end
        
        function [dX, dW] = backward(~, ...
                X, weights, dZ, ...
                topPad, leftPad, bottomPad, rightPad, ...
                verticalStride, horizontalStride)
            
            paddingSize = [topPad bottomPad leftPad rightPad];
            needsWeightGradients = nargout > 1;
            
            weightsFP=weights;  %%%%%%% %%%%%%% %%%%%%% %%%%%%%
            weights= sign(weights);  %%%%%%% %%%%%%% %%%%%%%
            weights(weights==0)=1; %%%%%%% %%%%%%% %%%%%%%
            
            
            if iPaddingIsSymmetric(paddingSize)
                dX = nnet.internal.cnngpu.convolveForward2D( ...
                    dZ, weights, ...
                    topPad, leftPad, bottomPad, rightPad, ...
                    verticalStride, horizontalStride);
            
                if needsWeightGradients
                    
                    weights=weightsFP; %%%%%%%%%%%%%%%%%
                    
                    dW{1} = nnet.internal.cnngpu.convolveBackwardFilter2D( ...
                        dZ, weights, X, ...
                        topPad, leftPad, bottomPad, rightPad, ...
                        verticalStride, horizontalStride);

                    dW{2} = nnet.internal.cnngpu.convolveBackwardBias2D(dZ);
                end
            else
                dZ = iPadArray(dZ, paddingSize);
                dX = nnet.internal.cnngpu.convolveForward2D( ...
                    dZ, weights, ...
                    0, 0, 0, 0, ...
                    verticalStride, horizontalStride);
            
                if needsWeightGradients
                    
                    weights=weightsFP; %%%%%%%%%%%%%%%%%
                    
                    dW{1} = nnet.internal.cnngpu.convolveBackwardFilter2D( ...
                        dZ, weights, X, ...
                        0, 0, 0, 0, ...
                        verticalStride, horizontalStride);

                    dZ = iUnpadArray(dZ, paddingSize);
                    dW{2} = nnet.internal.cnngpu.convolveBackwardBias2D(dZ);
                end
            end
        end
        
    end
end

function tf = iPaddingIsSymmetric(paddingSize)
tf = nnet.internal.cnn.layer.padding.isPaddingSymmetric(paddingSize);
end

function outputArray = iPadArray(inputArray, paddingSize)
outputArray = nnet.internal.cnn.layer.padding.padArray(inputArray, paddingSize);
end

function outputArray = iUnpadArray(inputArray, paddingSize)
outputArray = nnet.internal.cnn.layer.padding.unpadArray(inputArray, paddingSize);
end