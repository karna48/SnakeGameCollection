function [idx_A] = enumerate(A)
    D = size(A);
    idx = cell(1, numel(D));
    [idx{:}] = ind2sub(D, 1:numel(A));
    idx_A = cell(2, numel(A));
    for i = 1:numel(A)
        idx_mat = zeros(1, numel(D));
        for d_i = 1:numel(D)
            idx_mat(d_i) = idx{d_i}(i);
        end
        idx_A{1, i} = idx_mat;
        if iscell(A)
            idx_A{2, i} = A{i};
        else
            idx_A{2, i} = A(i);
        end
    end
end
