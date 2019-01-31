function D = findListDistances(data1,data2)

    N = length(data1(:,1));
    M = length(data2(:,1));
    
    D = zeros(N,M);
    for i=1:N
        for j=1:M
            D(i,j) = norm(data1(i,:) - data2(j,:));
        end
    end