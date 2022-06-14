function d = pcChamferDistance(p1, p2)
%%PCCHAMFERDISTANCE Chamfer Distance between two 3D point clouds
% D = PCCHAMFERDISTANCE(p1, p2) finds the nearest point of p1 in p2 and the
% nearest point of p2 in p1, and return the average of the square
% distances D.
%

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

assert(ismember(ndims(p1.Location), [2 3]), 'Error in point cloud location')
assert(ismember(ndims(p2.Location), [2 3]), 'Error in point cloud location')

d1 = pcChamferDistanceInternal(p1, p2);
d2 = pcChamferDistanceInternal(p2, p1);

d = d1+d2;

end

function s = pcChamferDistanceInternal(ptest, pref)
%calculate the euclidean distance for every point in the test point cloud 
% to the closest point in the reference point cloud. Returns the sum of the
% squared euclidian distances.

testLocation = ptest.Location;
refLocation = pref.Location;

if ismatrix(testLocation)
    Xt = reshape(testLocation(:,1), [], 1);
    Yt = reshape(testLocation(:,2), [], 1);
    Zt = reshape(testLocation(:,3), [], 1);
else
    Xt = reshape(testLocation(:,:,1), [], 1);
    Yt = reshape(testLocation(:,:,2), [], 1);
    Zt = reshape(testLocation(:,:,3), [], 1);
end

test = [Xt, Yt, Zt];
test(any(isnan(test),2),:) = [];

if ismatrix(refLocation)
    Xr = reshape(refLocation(:,1), [], 1);
    Yr = reshape(refLocation(:,2), [], 1);
    Zr = reshape(refLocation(:,3), [], 1);
else
    Xr = reshape(refLocation(:,:,1), [], 1);
    Yr = reshape(refLocation(:,:,2), [], 1);
    Zr = reshape(refLocation(:,:,3), [], 1);
end

ref = [Xr, Yr, Zr];
ref(any(isnan(ref),2),:) = [];

nTest = size(test,1);
id = zeros(nTest,1);

for i = 1:nTest
    dist = vecnorm(ref-test(i,:),2,2);
    [~,idmin] = min(dist);
    id(i) = idmin;
end

s  = sum(vecnorm(test-ref(id,:),2,2).^2)/nTest;

end