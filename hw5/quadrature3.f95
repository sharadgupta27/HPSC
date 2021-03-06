
module quadrature3

    use omp_lib

contains

real(kind=8) function trapezoid(f, a, b, n)

    ! Estimate the integral of f(x) from a to b using the
    ! Trapezoid Rule with n points.

    ! Input:
    !   f:  the function to integrate
    !   a:  left endpoint
    !   b:  right endpoint
    !   n:  number of points to use
    ! Returns:
    !   the estimate of the integral
     
    implicit none
    real(kind=8), intent(in) :: a,b
    real(kind=8), external :: f
    integer, intent(in) :: n

    ! Local variables:
    integer :: j
    real(kind=8) :: h, trap_sum, xj

    h = (b-a)/(n-1)
    trap_sum = 0.5*(f(a) + f(b))  ! endpoint contributions
     
    do j=2,n-1
        xj = a + (j-1)*h
        trap_sum = trap_sum + f(xj)
        enddo

    trapezoid = h * trap_sum

end function trapezoid

real(kind=8) function simpson(f, a, b, n) result(simp_sum)
    !
    !
    !
    implicit none
    interface
        real(kind=8) function f(x)
            implicit none
            real(kind=8), intent(in) :: x
        end function f
    end interface
    
    ! input arguments 
    real(kind=8), intent(in) :: a, b
    integer, intent(in) :: n

    ! local variables
    real(kind=8) :: h, xc, xj
    integer :: k

    h = (b - a) / real(n)
    simp_sum = f(a) + f(b)
    !$omp parallel private(xj) reduction(+: simp_sum)
    !$omp do
    do k = 2, n - 1, 2
        xj = a + k*h
        simp_sum  = simp_sum + 2.*f(xj) 
    end do
    !$omp end do nowait
    !$omp end parallel
    !$omp parallel do private(xc) reduction(+: simp_sum)
    do k = 1, n, 2
        xc = a + h*k
        simp_sum = simp_sum + 4.*f(xc)
    end do
    !$omp end parallel do
    
    simp_sum = h/3.*simp_sum

end function simpson



subroutine error_table(f,a,b,nvals,int_true,method)

    ! Compute and print out a table of errors when the quadrature
    ! rule specified by the input function method is applied for
    ! each value of n in the array nvals.

    implicit none
    real(kind=8), intent(in) :: a,b, int_true
    real(kind=8), external :: f, method
    integer, dimension(:), intent(in) :: nvals

    ! Local variables:
    integer :: j, n
    real(kind=8) :: ratio, last_error, error, int_approx

    print *, "      n         approximation        error       ratio"
    last_error = 0.
    !$omp parallel do &
    !$omp private(error,ratio, int_approx, n) &
    !$omp firstprivate(last_error) &
    !$omp schedule(dynamic)
    do j=size(nvals), 1, -1
        n = nvals(j)
        int_approx = method(f,a,b,n)
        error = abs(int_approx - int_true)
        ratio = last_error / error
        last_error = error  ! for next n

        print 11, n, int_approx, error, ratio
 11     format(i8, es22.14, es13.3, es13.3)
    enddo
    !omp end parallel do 

end subroutine error_table


function linspace(a,b,n) result(linvector)
    real(kind=8), intent(in) :: a, b
    integer, intent(in) :: n
    real(kind=8) :: h, linvector(n)
    integer :: k
    h = (b - a) / real((n - 1))
    linvector(1) = a
    linvector(n) = b
    forall(k = 2:n-1) linvector(k) = a + (k-1)*h
end function linspace


end module quadrature3

