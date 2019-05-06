module calving
    ! Definitions for various calving laws 

    use yelmo_defs, only : sp, dp, prec 

    implicit none 


    private 

    public :: apply_calving
    public :: calc_calving_rate_simple
    public :: calc_calving_rate_flux 
    public :: calc_calving_rate_eigen
    public :: calc_calving_rate_kill 
    
contains 

    subroutine apply_calving(H_ice,calv,dt,H_min)

        implicit none 

        real(prec), intent(INOUT) :: H_ice(:,:) 
        real(prec), intent(INOUT) :: calv(:,:) 
        real(prec), intent(IN)    :: dt 
        real(prec), intent(IN)    :: H_min 
        
        ! Ensure calving is limited to amount of available ice to calve  
        where((H_ice-dt*calv) .lt. 0.0) calv = H_ice/dt

        ! Apply modified mass balance to update the ice thickness 
        H_ice = H_ice - dt*calv
        where (H_ice .le. H_min) H_ice = 0.0 

        return 
        
    end subroutine apply_calving

    function calc_calving_rate_simple(H_ice,f_grnd,f_ice,dt,H_calv) result(calv)
        ! Calculate the calving rate [m/a] based on a simple threshold rule
        ! H_ice < H_calv

        implicit none 

        real(prec), intent(IN) :: H_ice(:,:)                ! [m] Ice thickness 
        real(prec), intent(IN) :: f_grnd(:,:)               ! [-] Grounded fraction
        real(prec), intent(IN) :: f_ice(:,:)                ! [-] Ice area fraction
        real(prec), intent(IN) :: dt 
        real(prec), intent(IN) :: H_calv 
        real(prec) :: calv(size(H_ice,1),size(H_ice,2)) 

        ! Local variables 
        integer :: i, j, nx, ny
        real(prec) :: Hfrac
        logical :: is_front 
        integer :: n_ocean 

        nx = size(H_ice,1)
        ny = size(H_ice,2)
            
            
        ! Initially set calving rate to zero 
        calv = 0.0 

        do j=2,ny-1
        do i=2,nx-1

            ! Determine ice-shelf front as how many ocean points are bordering it

            if (f_grnd(i,j) .eq. 0.0 .and. f_ice(i,j) .gt. 0.0) then
                ! Ice shelf point

                n_ocean = count([f_grnd(i-1,j) .eq. 0.0 .and. f_ice(i-1,j).eq.0.0, &
                                 f_grnd(i+1,j) .eq. 0.0 .and. f_ice(i+1,j).eq.0.0, &
                                 f_grnd(i,j-1) .eq. 0.0 .and. f_ice(i,j-1).eq.0.0, &
                                 f_grnd(i,j+1) .eq. 0.0 .and. f_ice(i,j+1).eq.0.0])

            else
                ! No ocean points bordering point 

                n_ocean = 0 

            end if
            
            if (n_ocean .gt. 0) then 
                ! If this point is an ice front, check for calving

                ! Determine ice thickness accounting for fraction  
                if (f_ice(i,j) .gt. 0.0) then 
                    Hfrac = H_ice(i,j) / f_ice(i,j) 
                else 
                    Hfrac = 0.0
                end if

!                 if (n_ocean .gt. 0 .and. n_ocean .le. 2 .and. Hfrac .le. H_calv) then 
!                     ! Calculate calving rate if current point has thickness less than threshold. 

!                     calv(i,j) = H_ice(i,j) / dt  

!                 else if (n_ocean .gt. 2 .and. Hfrac .le. 2.0*H_calv) then 
!                     ! For more open ice front, set higher threshold for calving 

!                     calv(i,j) = H_ice(i,j) / dt 

!                 end if 

                if (n_ocean .gt. 0 .and. Hfrac .le. H_calv) then 
                    ! Apply calving at front, delete all ice in point (H_ice) 

                    calv(i,j) = H_ice(i,j) / dt 

                end if 

            end if

        end do
        end do

        return 

    end function calc_calving_rate_simple
    
    function calc_calving_rate_flux(H_ice,f_grnd,f_ice,mbal,ux_bar,uy_bar,dx,dt,H_calv) result(calv)
        ! Calculate the calving rate [m/a] based on a simple threshold rule
        ! H_ice < H_calv

        implicit none 

        real(prec), intent(IN) :: H_ice(:,:)                ! [m] Ice thickness 
        real(prec), intent(IN) :: f_grnd(:,:)               ! [-] Grounded fraction
        real(prec), intent(IN) :: f_ice(:,:)                ! [-] Ice area fraction
        real(prec), intent(IN) :: mbal(:,:)                 ! [m/a] Net mass balance 
        real(prec), intent(IN) :: ux_bar(:,:)               ! [m/a] velocity, x-direction (ac-nodes)
        real(prec), intent(IN) :: uy_bar(:,:)               ! [m/a] velocity, y-direction (ac-nodes)
        real(prec), intent(IN) :: dx, dt 
        real(prec), intent(IN) :: H_calv                    ! [m] Threshold for calving
        real(prec) :: calv(size(H_ice,1),size(H_ice,2)) 

        ! Local variables 
        integer :: i, j, nx, ny
        real(prec) :: eps_xx, eps_yy  
        logical :: test_mij, test_pij, test_imj, test_ipj
        logical :: positive_mb 
        real(prec), allocatable :: dHdt(:,:), Hdiff(:,:), Hfrac(:,:) 
        integer :: n_ocean 

        nx = size(H_ice,1)
        ny = size(H_ice,2)

        allocate(dHdt(nx,ny))
        allocate(Hdiff(nx,ny))
        allocate(Hfrac(nx,ny))

        ! Determine ice thickness accounting for fraction  
        where (H_ice .gt. 1.0 .and. f_ice .gt. 0.0) 
            Hfrac = H_ice / f_ice 
        elsewhere 
            Hfrac = 0.0
        end where 

        ! Ice thickness above threshold
        Hdiff = Hfrac - H_calv

        ! Diagnosed lagrangian rate of change
        dHdt = 0.0 

        do j = 2, ny
        do i = 2, nx
        
                ! Calculate strain rate locally (Aa node)
                ! Note: dx should probably account for f_ice somehow,  
                ! but this would only a minor adjustment
                eps_xx = (ux_bar(i,j) - ux_bar(i-1,j))/dx
                eps_yy = (uy_bar(i,j) - uy_bar(i,j-1))/dx

                ! Calculate thickness change via conservation
                dHdt(i,j) = mbal(i,j) - Hfrac(i,j)*(eps_xx+eps_yy)

        end do 
        end do
        

        ! Initially set calving rate to zero 
        calv = 0.0 

        do j = 2, ny-1
        do i = 2, nx-1

            ! Determine ice-shelf front as how many ocean points are bordering it

            if (f_grnd(i,j) .eq. 0.0 .and. f_ice(i,j) .gt. 0.0) then
                ! Ice shelf point

                n_ocean = count([f_grnd(i-1,j) .eq. 0.0 .and. f_ice(i-1,j).eq.0.0, &
                                 f_grnd(i+1,j) .eq. 0.0 .and. f_ice(i+1,j).eq.0.0, &
                                 f_grnd(i,j-1) .eq. 0.0 .and. f_ice(i,j-1).eq.0.0, &
                                 f_grnd(i,j+1) .eq. 0.0 .and. f_ice(i,j+1).eq.0.0])

            else
                ! No ocean points bordering point 

                n_ocean = 0 

            end if

            if (n_ocean .gt. 0 .and. Hdiff(i,j).le.0.0) then 
                ! Check if current point is at the floating ice front,
                ! and has thickness less than threshold, or if
                ! ice below H_calv limit, accounting for mass flux from inland

                positive_mb = (mbal(i,j).gt.0.0)

                test_mij = ( ((Hdiff(i-1,j).gt.0.0).and.(ux_bar(i,j).ge.0.0)  &  ! neighbor (i-1,j) total > hcoup
                    .and.  (dHdt(i-1,j).gt.(-Hdiff(i-1,j)*abs(ux_bar(i-1,j)/dx)))) & 
                    .or.(f_grnd(i-1,j).gt.0.0.and.positive_mb )) !

                test_pij = ( ((Hdiff(i+1,j).gt.0.0).and.(ux_bar(i+1,j).le.0.0) & ! neighbor (i+1,j) total > hcoup
                    .and.(dHdt(i+1,j).gt.(-Hdiff(i+1,j)*abs(ux_bar(i+1,j)/dx)))) &
                    .or.(f_grnd(i+1,j).gt.0.0.and.positive_mb) ) !

                test_imj = ( ((Hdiff(i,j-1).gt.0.0).and.(uy_bar(i,j).ge.0.0)  &  ! neighbor (i,j-1) total > hcoup
                    .and.(dHdt(i,j-1).gt.(-Hdiff(i,j-1)*abs(uy_bar(i,j-1)/dx))))&
                    .or.(f_grnd(i,j-1).gt.0.0.and.positive_mb ) ) !

                test_ipj = ( ((Hdiff(i,j+1).gt.0.0).and.(uy_bar(i,j+1).le.0.0) & ! neighbor (i,j+1) total > hcoup
                    .and.(dHdt(i,j+1).gt.(-Hdiff(i,j+1)*abs(uy_bar(i,j+1)/dx))))&
                    .or.(f_grnd(i,j+1).gt.0.0.and.positive_mb ) ) !

                if ((.not.(test_mij.or.test_pij.or.test_imj.or.test_ipj))) then
                    calv(i,j) = Hfrac(i,j) / dt             
                end if  

            end if

        end do
        end do

        return 

    end function calc_calving_rate_flux
    
    function calc_calving_rate_eigen(H_ice,is_float,f_ice,ux_bar,uy_bar,dx,dy,dt,H_calv,k_calv) result(calv)
        ! Calculate the calving rate [m/a] based on the "eigencalving" law
        ! from Levermann et al. (2012)

        implicit none 

        real(prec), intent(IN) :: H_ice(:,:)
        logical,    intent(IN) :: is_float(:,:) 
        real(prec), intent(IN) :: f_ice(:,:)   
        real(prec), intent(IN) :: ux_bar(:,:), uy_bar(:,:)
        real(prec), intent(IN) :: dx, dy, dt 
        real(prec), intent(IN) :: H_calv 
        real(prec), intent(IN) :: k_calv
        real(prec) :: calv(size(H_ice,1),size(H_ice,2)) 

        ! Local variables 
        integer :: i, j, nx, ny
        real(prec), allocatable :: eps_xx(:,:), eps_yy(:,:) 
        real(prec) :: eps_xx_max, eps_yy_max 
        integer :: imax_xx, jmax_xx, imax_yy, jmax_yy                                          
        real(prec), allocatable :: spr(:,:)   ! total spreading rate in the two directions epsxx * epsyyy 

        logical, allocatable :: is_front(:,:)   
        integer :: n_ocean 

        nx = size(H_ice,1)
        ny = size(H_ice,2)

        allocate(spr(nx,ny),eps_xx(nx,ny),eps_yy(nx,ny))
        allocate(is_front(nx,ny))

        ! Determine grid points with shelf ice that are bordered by ice-free points
        is_front = .FALSE.
        do i=2,nx-1
        do j=2,ny-1

            if (is_float(i,j) .and. f_ice(i,j) .gt. 0.0) then

                n_ocean = count([is_float(i-1,j) .and. f_ice(i-1,j).eq.0.0, &
                                 is_float(i+1,j) .and. f_ice(i+1,j).eq.0.0, &
                                 is_float(i,j-1) .and. f_ice(i,j-1).eq.0.0, &
                                 is_float(i,j+1) .and. f_ice(i,j+1).eq.0.0])

                is_front(i,j) = (n_ocean .gt. 0)
            end if

        end do
        end do

        do j = 1, ny
            do i = 1, nx
                ! Calculate strain rate locally (Aa node)
                eps_xx(i,j) = (ux_bar(i,j) - ux_bar(i-1,j))/dx
                eps_yy(i,j) = (uy_bar(i,j) - uy_bar(i,j-1))/dy            
            end do
        end do
        
        ! PISM-like flux condition + calving rate with spreading:       
        calv = 0.0 
        do j = 2, ny-1
            do i = 2, nx-1  
                
                if( is_front(i,j) ) then                  ! Check if current point is floating, at the ice front                      

                    if ((eps_xx(i,j).gt.0.0).and.(eps_yy(i,j).gt.0.0)) then     ! divergence in both directions               
                        calv(i,j) = k_calv * eps_xx(i,j) * eps_yy(i,j) / dt     ! calving law                                        
                    else
                        calv(i,j) = 0.0                                         ! no calving because of no divergence
                    end if

                end if

            end do
        end do

        return 

    end function calc_calving_rate_eigen

    function calc_calving_rate_kill(H_ice,f_grnd,dt) result(calv)

        implicit none 

        real(prec), intent(IN) :: H_ice(:,:)
        real(prec), intent(IN) :: f_grnd(:,:) 
        real(prec), intent(IN) :: dt 
        real(prec) :: calv(size(H_ice,1),size(H_ice,2)) 

        ! Kill all floating ice, including partially grounded ice
        where (f_grnd .lt. 1.0) calv = H_ice / dt 

        return 

    end function calc_calving_rate_kill

end module calving 
