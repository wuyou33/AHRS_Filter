classdef JustaAHRSPureFast < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SamplePeriod = 1/256;
        Quaternion = [1 0 0 0];     % output quaternion describing the Earth relative to the sensor
        Beta = 1;               	% algorithm gain
        
        test=[0 0 0 0];
        test2=[0 0 0 0];
        gain=0.0528152;
        wAcc=0.00248;
        wMag=1.35e-04;
        
        mr_z=0.895;
        
        Imu=1;
    end
    
    methods (Access = public)
        function obj = JustaAHRSPureFast(varargin)
            for i = 1:2:nargin
                if  strcmp(varargin{i}, 'SamplePeriod'), obj.SamplePeriod = varargin{i+1};
                elseif  strcmp(varargin{i}, 'Quaternion'), obj.Quaternion = varargin{i+1};
                elseif  strcmp(varargin{i}, 'Beta'), obj.Beta = varargin{i+1};
                else error('Invalid argument');
                end
            end;
        end
        function obj = Update(obj, Gyroscope, Accelerometer, Magnetometer)
            q = obj.Quaternion; % short name local variable for readability
            
            % Normalise accelerometer measurement
            if(norm(Accelerometer) == 0), return; end	% handle NaN
            acc = Accelerometer / norm(Accelerometer);	% normalise magnitude
            
            % Normalise magnetometer measurement
            if(norm(Magnetometer) == 0), return; end	% handle NaN
            mag = Magnetometer / norm(Magnetometer);	% normalise magnitude
            
            
            qDot=0.5 *obj.SamplePeriod * quaternProd(q, [0 Gyroscope(1) Gyroscope(2) Gyroscope(3)]);
            qp= q + qDot;
            qp=qp/norm(qp);
            
            R=[2*(0.5 - qp(3)^2 - qp(4)^2)   0   2*(qp(2)*qp(4) - qp(1)*qp(3))
                2*(qp(2)*qp(3) - qp(1)*qp(4))  0  2*(qp(1)*qp(2) + qp(3)*qp(4))
                2*(qp(1)*qp(3) + qp(2)*qp(4))  0  2*(0.5 - qp(2)^2 - qp(3)^2)];
            
            ar=[0 0 1];
            accMesPred=(R*ar')';
            
            h = quaternProd(q, quaternProd([0 mag], quaternConj(q)));
            mr = [norm([h(2) h(3)]) 0 h(4)]/norm([norm([h(2) h(3)]) 0 h(4)]);
%             obj.mr_z= dot(accMesPred,mag);
%             mr_x=sqrt(1-obj.mr_z^2);
%             mr=[mr_x 0 obj.mr_z];
            magMesPred=(R*mr')';
                        
            ca=cross(acc,accMesPred);
            na=norm(ca);
            veca=ca/na;
            
            phia=(asin(na)*obj.gain);
            
            if(phia>obj.wAcc)
                phia=obj.wAcc;
            end
            
            cm=cross(mag,magMesPred);
            n=norm(cm);
            vecm=cm/n;
            
            phim=(asin(n)*obj.gain);            

            if(phim>obj.wMag)
                phim=obj.wMag;
            end
            %             phim=obj.wMag;
            qCor=[1 veca*phia/2+vecm*phim/2];
            
            obj.test=[real(asin(na)) real(asin(n)) 0 0];
            
            quat=quaternProd(qp,qCor);
            
            %             quat=quatGyrPred;
            if(quat(1)<0)
                quat=-quat;
            end
            
            
            obj.Quaternion = quat/norm(quat);
        end
        
        function obj = UpdateIMU(obj, Gyroscope, Accelerometer)
            q = obj.Quaternion; % short name local variable for readability
            
            % Normalise accelerometer measurement
            if(norm(Accelerometer) == 0), return; end	% handle NaN
            acc = Accelerometer / norm(Accelerometer);	% normalise magnitude
            
            qDot=0.5 *obj.SamplePeriod * quaternProd(q, [0 Gyroscope(1) Gyroscope(2) Gyroscope(3)]);
            qp= q + qDot;
            qp=qp/norm(qp);
            ar=[0 0 1];
            
            R=[0 0  2*(qp(2)*qp(4) - qp(1)*qp(3))
                0 0  2*(qp(1)*qp(2) + qp(3)*qp(4))
                0 0  qp(1)^2-qp(2)^2-qp(3)^2+qp(4)^2];
            
            accMesPred=(R*ar')';
            
            ca=cross(acc,accMesPred);
            n=norm(ca);
            veca=ca/n;
            phia=obj.wAcc/cos(asin(n));

            qCor=[1 veca*phia/2];
            obj.test=qCor;
            quat=quaternProd(qp,qCor);
            
            if(quat(1)<0)
                quat=-quat;
            end
            
            obj.Quaternion = quat/norm(quat);
        end
        
    end
    
end

