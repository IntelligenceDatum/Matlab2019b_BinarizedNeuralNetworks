classdef BinarizedTransposedConvolution2DHostStrategy < nnet.internal.cnn.layer.util.ExecutionStrategy
    % TransposedConvolution2DHostStrategy
    %     Execution strategy for running transposed convolution on the host
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    
    methods
        function [Z, memory] = forward(~, X, ...
                weights, bias, ...
                topPad, leftPad, bottomPad, rightPad, ...
                verticalStride, horizontalStride, ...
                verticalOutputSizeOffset, horizontalOutputSizeOffset)
            
            
            weights= sign(weights);  %%%%%%%%%%%%%%%%%%%%%
            weights(weights==0)=1;  %%%%%%%%%%%%%%%%%%%%%
            
            sz = BinarizedTransposedConvolution2D...
                .outputSize(X, weights, ...
                topPad, leftPad, bottomPad, rightPad, ...
                verticalStride, horizontalStride, ...
                verticalOutputSizeOffset, horizontalOutputSizeOffset);
            
            imageHeight = sz(1);
            imageWidth  = sz(2);
            if isa(X, 'single') && nnet.internal.cnnhost.useMKLDNN
                Z = nnet.internal.cnnhost.convolveBackward2D(...
                    weights, X, ...
                    topPad, leftPad, bottomPad, rightPad, ...
                    verticalStride, horizontalStride);
            else
                Z = nnet.internal.cnnhost.convolveBackwardData2DCore(...
                    [imageHeight, imageWidth], weights, X, ...
                    topPad, leftPad, bottomPad, rightPad, ...
                    verticalStride, horizontalStride);
            end
            
            % add bias
            Z = Z + bias;
            
            memory = [];
            
        end
        
        function [dX, dW] = backward( ~, ...
                X, weights, dZ, ...
                topPad, leftPad, bottomPad, rightPad, ...
                verticalStride, horizontalStride)
            needsWeightGradients = nargout > 1;
            
            
            weightsFP=weights;  %%%%%%% %%%%%%% %%%%%%% %%%%%%%
            weights= sign(weights);  %%%%%%% %%%%%%% %%%%%%%
            weights(weights==0)=1; %%%%%%% %%%%%%% %%%%%%%
            
            
            if isa(X, 'single') && nnet.internal.cnnhost.useMKLDNN
                dX = nnet.internal.cnnhost.convolveForward2D( ...
                    dZ, weights, ...
                    verticalPad, horizontalPad, ...
                    verticalPad, horizontalPad, ...
                    verticalStride, horizontalStride);
                
                if needsWeightGradients
                    
                    weights=weightsFP; %%%%%%%%%%%%%%%%%
                    
                    [~, dW{1}] = nnet.internal.cnnhost.convolveBackward2D( ...
                        dZ, weights, X, ...
                        topPad, leftPad, bottomPad, rightPad, ...
                        verticalStride, horizontalStride);
                    dW{2} = nnet.internal.cnnhost.convolveBackwardBias2D(dZ);
                end
            else
                dX = nnet.internal.cnnhost.stridedConv( ...
                    dZ, weights, ...
                    topPad, leftPad, bottomPad, rightPad, ...
                    verticalStride, horizontalStride);
                
                if needsWeightGradients
                    
                    weights=weightsFP; %%%%%%%%%%%%%%%%%
                    
                    dW{1} = nnet.internal.cnnhost.convolveBackwardFilter2D( ...
                        dZ, weights, X, ...
                        topPad, leftPad, bottomPad, rightPad, ...
                        verticalStride, horizontalStride);
                    dW{2} = nnet.internal.cnnhost.convolveBackwardBias2D(dZ);
                end
            end
            
            
        end
        
    end
    
end
