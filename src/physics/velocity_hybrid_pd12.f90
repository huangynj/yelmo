module velocity_hybrid_pd12

    use yelmo_defs ,only  : sp, dp, prec, tol_underflow, rho_ice, rho_sw, rho_w, g
    use yelmo_tools, only : stagger_aa_ab, stagger_aa_ab_ice, integrate_trapezoid1D_pt

    implicit none 

    private 
    
    public :: calc_vel_basal
    public :: calc_shear_reduction
    public :: calc_shear_3D
    public :: calc_basal_stress
    public :: calc_visc_eff_2D
    public :: calc_stress_eff_horizontal_squared

contains 

    subroutine calc_vel_basal(ux_b,uy_b,ux_bar,uy_bar,ux_i,uy_i)
        ! Calculate basal sliding from the difference of
        ! vertical mean velocity and vertical mean internal shear velocity
        ! Pollard and de Conto (2012), after Eqs. 2a & 2b
        
        implicit none
        
        real(prec), intent(OUT) :: ux_b(:,:) 
        real(prec), intent(OUT) :: uy_b(:,:)
        real(prec), intent(IN)  :: ux_bar(:,:) 
        real(prec), intent(IN)  :: uy_bar(:,:)
        real(prec), intent(IN)  :: ux_i(:,:) 
        real(prec), intent(IN)  :: uy_i(:,:)
        
        real(prec), parameter :: du_tol = 0.0_prec

        where(abs(ux_bar-ux_i) .gt. du_tol)
            ux_b = sign(ux_bar-ux_i,ux_bar)
        elsewhere
            ux_b = 0.0_prec
        end where
        
        where(abs(uy_bar-uy_i) .gt. du_tol)
            uy_b = sign(uy_bar-uy_i,uy_bar)
        elsewhere
            uy_b = 0.0_prec
        end where
        
        return
        
    end subroutine calc_vel_basal

    subroutine calc_shear_reduction(lhs_x,lhs_y,ux_b,uy_b,visc_eff,dx)
        ! Calculate reduction in driving stress expected from
        ! basal sliding
        ! Pollard and de Conto (2012), obtained from Eqs. 2a/2b
        
        implicit none
        
        real(prec), intent(OUT) :: lhs_x(:,:)    ! acx node
        real(prec), intent(OUT) :: lhs_y(:,:)    ! acy node
        real(prec), intent(IN)  :: ux_b(:,:)     ! acx node
        real(prec), intent(IN)  :: uy_b(:,:)     ! acx node 
        real(prec), intent(IN)  :: visc_eff(:,:) ! aa node 
        real(prec), intent(IN)  :: dx 

        ! Local variables 
        integer :: i, j, nx, ny 
        real(prec) :: dy 
        real(prec) :: duxdx, duydy, duydx, duxdy 
        real(prec), allocatable :: varx1_aa(:,:), vary1_aa(:,:) 
        real(prec), allocatable :: varx2_aa(:,:), vary2_aa(:,:) 

        ! Assume dx and dy are the same 
        dy = dx 

        ! Get matrix sizes 
        nx = size(lhs_x,1)
        ny = size(lhs_x,2) 

        allocate(varx1_aa(nx,ny))
        allocate(vary1_aa(nx,ny)) 
        allocate(varx2_aa(nx,ny))
        allocate(vary2_aa(nx,ny)) 

        ! Initially set lhs equal to zero
        lhs_x = 0.0
        lhs_y = 0.0
        
        varx1_aa = 0.0 
        vary1_aa = 0.0 
        varx2_aa = 0.0 
        vary2_aa = 0.0 

        ! First get arrays of intermediate values
        do j = 2, ny-1 
        do i = 2, nx-1 

            ! Calculate intermediate terms of
            ! lhs_x: 2*visc*(2*dudx+dvdy), visc*(dudy+dvdx)
            ! lhs_y: 2*visc*(2*dvdy+dudx), visc*(dudy+dvdx)
            ! on aa nodes 

            ! Gradients on aa nodes 
            duxdx = (ux_b(i,j)-ux_b(i-1,j))/dx 
            duydy = (uy_b(i,j)-uy_b(i,j-1))/dy 

            ! Cross terms on aa nodes 
            duxdy  = ( 0.25_prec*(ux_b(i,j)+ux_b(i-1,j)+ux_b(i,j+1)+ux_b(i-1,j+1)) &
                      -0.25_prec*(ux_b(i,j)+ux_b(i-1,j)+ux_b(i,j-1)+ux_b(i-1,j-1))) /dy 

            duydx  = ( 0.25_prec*(uy_b(i,j)+uy_b(i,j-1)+uy_b(i+1,j)+uy_b(i+1,j-1)) &
                      -0.25_prec*(uy_b(i,j)+uy_b(i,j-1)+uy_b(i-1,j)+uy_b(i-1,j-1))) /dx  

            ! Intermediate terms on aa nodes - x-direction  
            varx1_aa(i,j) = 2.0_prec*visc_eff(i,j)*(2.0_prec*duxdx+duydy)
            vary1_aa(i,j) = visc_eff(i,j)*(duxdy+duydx)

            ! Intermediate terms on aa nodes - y-direction  
            vary2_aa(i,j) = 2.0_prec*visc_eff(i,j)*(2.0_prec*duydy+duxdx)
            varx2_aa(i,j) = visc_eff(i,j)*(duxdy+duydx)

        end do 
        end do 

        ! Next calculate the total lhs_x term, on acx nodes 
        do j = 2, ny-1 
        do i = 1, nx-1 

            ! On acx nodes 
            duxdx = (varx1_aa(i+1,j)-varx1_aa(i,j))/dx 
            duxdy = ( 0.25_prec*(vary1_aa(i,j)+vary1_aa(i+1,j)+vary1_aa(i,j+1)+vary1_aa(i+1,j+1)) &
                     -0.25_prec*(vary1_aa(i,j)+vary1_aa(i+1,j)+vary1_aa(i,j-1)+vary1_aa(i+1,j-1))) /dy

            lhs_x(i,j) = duxdx + duydy 

        end do 
        end do 

        ! Next calculate the total lhs_y term, on acy nodes 
        do j = 1, ny-1 
        do i = 2, nx-1 

            ! On acy nodes 
            duydy = (vary2_aa(i,j+1)-vary2_aa(i,j))/dy 

            duydx = ( 0.25_prec*(varx2_aa(i,j)+varx2_aa(i+1,j)+varx2_aa(i,j+1)+varx2_aa(i+1,j+1)) &
                     -0.25_prec*(varx2_aa(i,j)+varx2_aa(i,j+1)+varx2_aa(i-1,j)+varx2_aa(i-1,j+1))) /dx

            lhs_y(i,j) = duydy + duydx 

        end do 
        end do 

        return
        
    end subroutine calc_shear_reduction
    
    subroutine calc_shear_3D(duxdz,duydz,dd_ab,taud_acx,taud_acy,ATT,lhs_x,lhs_y, &
                             sigma_horiz_sq,zeta_aa,n_glen,boundaries)
        ! Calculate internal shear via SIA minus stretching
        ! Pollard and de Conto (2012), Eq. 1
        ! Calculate coefficients on Ab nodes, then
        ! stagger to ac nodes for each component 
        
        implicit none
        
        real(prec), intent(OUT) :: duxdz(:,:,:)         ! nx,ny,nz_aa [1/a]
        real(prec), intent(OUT) :: duydz(:,:,:)         ! nx,ny,nz_aa [1/a]
        real(prec), intent(OUT) :: dd_ab(:,:,:)         ! nx,ny,nz_aa [m2/a]
        real(prec), intent(IN)  :: taud_acx(:,:)        ! dzsdx(:,:)
        real(prec), intent(IN)  :: taud_acy(:,:)        ! dzsdy(:,:) 
        real(prec), intent(IN)  :: ATT(:,:,:)           ! nx,ny,nz_aa 
        real(prec), intent(IN)  :: lhs_x(:,:)           ! ac-nodes
        real(prec), intent(IN)  :: lhs_y(:,:)           ! ac-nodes
        real(prec), intent(IN)  :: sigma_horiz_sq(:,:)  ! [Pa], aa-nodes
        real(prec), intent(IN)  :: zeta_aa(:)           ! Vertical axis
        real(prec), intent(IN)  :: n_glen               ! Glen law exponent
        character(len=*), intent(IN) :: boundaries      ! Boundary conditions to apply 

        ! Local variables
        integer    :: i, j, k, nx, ny, nz_aa 
        real(prec) :: exp1, depth    
        real(prec), allocatable :: sigma_ab(:,:)
        real(prec), allocatable :: sigma_xz_ab(:,:), sigma_yz_ab(:,:)   ! [Pa]
        real(prec), allocatable :: sigma_xz(:,:), sigma_yz(:,:)         ! [Pa]
        real(prec), allocatable :: sigma_horiz_sq_ab(:,:)               ! [Pa]
        real(prec), allocatable :: sigma_tot_sq_ab(:,:)                 ! [Pa]
        real(prec) :: ATT_ab, ddx, ddy 
        real(prec) :: ATT_ac, sigma_tot_sq_ac
        logical :: is_mismip 

        is_mismip = .FALSE. 
        if (trim(boundaries) .eq. "MISMIP3D") is_mismip = .TRUE. 

        ! Define exponent for later use 
        exp1 = (n_glen-1.0_prec)/2.0_prec 

        ! Get array dimensions
        nx    = size(duxdz,1)
        ny    = size(duxdz,2)
        nz_aa = size(zeta_aa,1)

        ! Allocate local variables  
        allocate(sigma_ab(nx,ny)) 
        allocate(sigma_xz_ab(nx,ny)) 
        allocate(sigma_yz_ab(nx,ny)) 
        allocate(sigma_xz(nx,ny)) 
        allocate(sigma_yz(nx,ny))
        allocate(sigma_horiz_sq_ab(nx,ny))
        allocate(sigma_tot_sq_ab(nx,ny))

        ! Initially set shear to zero everywhere 
        ! (and diagnostic diffusion variable)
        duxdz   = 0.0
        duydz   = 0.0
        dd_ab   = 0.0  

        ! Stagger horizontal stress contribution to ab-nodes 
        sigma_horiz_sq_ab = stagger_aa_ab(sigma_horiz_sq)

        ! Calculate shear for each layer of the ice sheet 
        ! with diffusivity on Ab nodes (ie, EISMINT type I)

        do k = 1, nz_aa 

            ! Determine current depth fraction
            depth = (1.0_prec-zeta_aa(k))

            ! Determine the vertical shear for current layer (ac-nodes)
            ! Pollard and de Conto (2012), Eq. 3 
            ! ajr: note, initial negative sign moved to be explicit
            ! in the final calculation of dux/dz duy/dz, so that 
            ! the definition of diffusivity dd_ab is consistent with
            ! other SIA derivations  
!             sigma_xz = (rhog*H_ice_acx*dzsdx - lhs_x)*depth
!             sigma_yz = (rhog*H_ice_acy*dzsdy - lhs_y)*depth
            sigma_xz = (taud_acx - lhs_x)*depth
            sigma_yz = (taud_acy - lhs_y)*depth
            
            ! Acx => Ab
            sigma_xz_ab = 0.0 
            do j = 1, ny-1
            do i = 1, nx 
                sigma_xz_ab(i,j) = 0.5_prec*(sigma_xz(i,j)+sigma_xz(i,j+1))
            end do 
            end do 

            ! Acy => Ab
            sigma_yz_ab = 0.0
            do j = 1, ny
            do i = 1, nx-1 
                sigma_yz_ab(i,j) = 0.5_prec*(sigma_yz(i,j)+sigma_yz(i+1,j))
            end do 
            end do 

            ! Get total sigma terms squared (input to Eq. 1a/1b) on ab-nodes
            ! with stress from horizontal stretching `sigma_horiz_sq`
            sigma_tot_sq_ab = sigma_xz_ab**2 + sigma_yz_ab**2 + sigma_horiz_sq_ab
            
            ! Determine the diffusivity for current layer on Ab nodes
            ! Pollard and de Conto (2012), Eq. 1a/dd 
            do j = 1, ny-1
            do i = 1, nx-1 

                ! Stagger rate factor: Aa => Ab nodes
                ATT_ab       = 0.25_prec * (ATT(i,j,k)+ATT(i+1,j,k)+ATT(i,j+1,k)+ATT(i+1,j+1,k))

                ! Calculate diffusivity on Ab nodes
                dd_ab(i,j,k) = 2.0_prec*ATT_ab*(sigma_tot_sq_ab(i,j)**exp1)
            end do 
            end do

            ! Calculate the shear for current layer on Ac nodes
            ! Pollard and de Conto (2012), Eq. 1a/1b
            ! Ac-x nodes
            do j = 2, ny
            do i = 1, nx 

                ! Get sigma_tot on ac-nodes 
                !sigma_tot_sq_ac = 0.5_prec * (sigma_tot_sq_ab(i,j-1)+sigma_tot_sq_ab(i,j))
                !ATT_ac          = 0.5_prec * (ATT(i,j,k) + ATT(i+1,j,k))
                !ddx             = 2.0_prec * ATT_ac * (sigma_tot_sq_ac**exp1)

                ! Get coefficient on Ac nodes
                ddx = 0.5_prec*(dd_ab(i,j,k)+dd_ab(i,j-1,k))

                ! Calculate shear on ac nodes 
                duxdz(i,j,k) = -ddx*sigma_xz(i,j)

            end do 
            end do

            ! Ac-y nodes
            do j = 1, ny
            do i = 2, nx 

                ! Get sigma_tot on ac-nodes 
                !sigma_tot_sq_ac = 0.5_prec * (sigma_tot_sq_ab(i-1,j)+sigma_tot_sq_ab(i,j))
                !ATT_ac          = 0.5_prec * (ATT(i,j,k) + ATT(i,j+1,k))
                !ddy             = 2.0_prec * ATT_ac * (sigma_tot_sq_ac**exp1)
                
                ! Get coefficient on Ac nodes
                ddy = 0.5_prec*(dd_ab(i,j,k)+dd_ab(i-1,j,k))

                ! Calculate shear on ac nodes 
                duydz(i,j,k) = -ddy*sigma_yz(i,j)

            end do 
            end do
            
        end do 

        if (is_mismip) then 
            ! Fill in boundaries 
            ! ajr, 2018-11-12: mismip is still showing slight assymmetry in the y-direction when 
            ! shear is included in solution (ie, mix_method=1). Could be related to boundary conditions here.

            duxdz(:,1,:)  = duxdz(:,2,:) 
            duxdz(:,ny,:) = duxdz(:,ny-1,:) 
            duydz(:,1,:)  = duydz(:,2,:) 
            duydz(:,ny,:) = duydz(:,ny-1,:) 
            
            duxdz(1,:,:)  = duxdz(2,:,:) 
            duxdz(nx,:,:) = duxdz(nx-1,:,:) 
            duydz(1,:,:)  = duydz(2,:,:) 
            duydz(nx,:,:) = duydz(nx-1,:,:) 
            
        end if 

        return
        
    end subroutine calc_shear_3D
    
    function calc_visc_eff_2D(ux,uy,duxdz,duydz,H_ice,ATT,zeta_aa,dx,dy,n) result(visc)
        ! Calculate effective viscosity eta to be used in SSA solver
        ! Pollard and de Conto (2012), Eqs. 2a/b and Eq. 4 (`visc=mu*H_ice*A**(-1/n)`)
        ! Note: calculated on same nodes as eps_sq (aa-nodes by default)
        ! Note: this is equivalent to the vertically-integrated viscosity, 
        ! since it is multiplied with H_ice 

        implicit none 
        
        real(prec), intent(IN) :: ux(:,:)      ! Vertically averaged horizontal velocity, x-component
        real(prec), intent(IN) :: uy(:,:)      ! Vertically averaged horizontal velocity, y-component
        real(prec), intent(IN) :: duxdz(:,:)   ! Only from internal shear, vertical mean (ac-nodes)
        real(prec), intent(IN) :: duydz(:,:)   ! Only from internal shear, vertical mean (ac-nodes)
        real(prec), intent(IN) :: H_ice(:,:)   ! Ice thickness
        real(prec), intent(IN) :: ATT(:,:,:)   ! nx,ny,nz_aa Rate factor
        real(prec), intent(IN) :: zeta_aa(:)  ! Vertical axis (sigma-coordinates from 0 to 1)
        real(prec), intent(IN) :: dx, dy
        real(prec), intent(IN) :: n
        real(prec) :: visc(size(ux,1),size(ux,2))   ! [Pa a m]
        
        ! Local variables 
        integer :: i, j, nx, ny, k, nz_aa 
        integer :: im1, ip1, jm1, jp1  
        real(prec) :: inv_4dx, inv_4dy
        real(prec) :: dudx, dudy
        real(prec) :: dvdx, dvdy 
        real(prec) :: duxdz_aa, duydz_aa
        real(prec) :: eps_sq, mu  

        real(prec), allocatable :: visc1D(:) 
        
        real(prec), parameter :: visc_min     = 1e3_prec 
        real(prec), parameter :: epsilon_sq_0 = 1e-6_prec   ! [a^-1] Bueler and Brown (2009), Eq. 26
        
        nx    = size(ux,1)
        ny    = size(ux,2)
        nz_aa = size(zeta_aa,1) 

        allocate(visc1D(nz_aa))

        inv_4dx = 1.0_prec / (4.0_prec*dx) 
        inv_4dy = 1.0_prec / (4.0_prec*dy) 

        ! Initialize viscosity to minimum value 
        visc = visc_min 
        
        ! Loop over domain to calculate viscosity at each aa-node
         
        do j = 1, ny
        do i = 1, nx

            im1 = max(i-1,1) 
            ip1 = min(i+1,nx) 
            jm1 = max(j-1,1) 
            jp1 = min(j+1,ny) 
            
            ! 1. Calculate effective strain components from horizontal stretching

            ! Aa node
            dudx = (ux(i,j) - ux(im1,j))/dx
            dvdy = (uy(i,j) - uy(i,jm1))/dy

            ! Calculation of cross terms on central aa-nodes (symmetrical results)
            dudy = ((ux(i,jp1)   - ux(i,jm1))    &
                  + (ux(im1,jp1) - ux(im1,jm1))) * inv_4dx 
            dvdx = ((uy(ip1,j)   - uy(im1,j))    &
                  + (uy(ip1,jm1) - uy(im1,jm1))) * inv_4dy 

            ! 2. Un-stagger shear terms to central aa-nodes

            duxdz_aa = 0.5_prec*(duxdz(i,j) + duxdz(im1,j))
            duydz_aa = 0.5_prec*(duydz(i,j) + duydz(i,jm1))
            
            ! Avoid underflows 
            if (abs(dudx) .lt. tol_underflow) dudx = 0.0 
            if (abs(dvdy) .lt. tol_underflow) dvdy = 0.0 
            if (abs(dudy) .lt. tol_underflow) dudy = 0.0 
            if (abs(dvdx) .lt. tol_underflow) dvdx = 0.0 

            if (abs(duxdz_aa) .lt. tol_underflow) duxdz_aa = 0.0 
            if (abs(duydz_aa) .lt. tol_underflow) duydz_aa = 0.0 
            
            ! 3. Calculate the total effective strain rate
            ! from Pollard and de Conto (2012), Eq. 6
            ! (Note: equation in text seems to have typo concerning cross terms)

            eps_sq = dudx**2 + dvdy**2 + dudx*dvdy + 0.25*(dudy+dvdx)**2 &
                          + 0.25_prec*duxdz_aa**2 + 0.25_prec*duydz_aa**2 &
                          + epsilon_sq_0
            
            ! 4. Calculate the effective visocity (`eta` in Greve and Blatter, 2009)
            ! Pollard and de Conto (2012), Eqs. 2a/b and Eq. 4 (`visc=A**(-1/n)*mu*H_ice`)

            mu = 0.5_prec*(eps_sq)**((1.0_prec - n)/(2.0_prec*n))

            do k = 1, nz_aa 
                visc1D(k) = ATT(i,j,k)**(-1.0_prec/n) * mu
                
            end do 

            visc(i,j) = integrate_trapezoid1D_pt(visc1D,zeta_aa) 
            if (H_ice(i,j) .gt. 1.0_prec) visc(i,j) = visc(i,j) * H_ice(i,j) 
            
        end do 
        end do 

        return
        
    end function calc_visc_eff_2D

    function calc_stress_eff_horizontal_squared(ux,uy,ATT_bar,dx,dy,n) result(sigma_sq)
        ! Calculate squared effective stress of horizontal stretching terms
        ! (from vertically averaged quantities)
        ! as defined in Pollard and de Conto (2012), Eq. 7
        ! Note: calculated on aa-nodes 

        implicit none 
        
        real(prec), intent(IN) :: ux(:,:)      ! Vertically averaged horizontal velocity, x-component
        real(prec), intent(IN) :: uy(:,:)      ! Vertically averaged horizontal velocity, y-component
        real(prec), intent(IN) :: ATT_bar(:,:)   ! nx,ny,nz_aa Rate factor
        real(prec), intent(IN) :: dx, dy
        real(prec), intent(IN) :: n
        real(prec) :: sigma_sq(size(ux,1),size(ux,2))
        
        ! Local variables 
        integer :: i, j, nx, ny 
        integer :: im1, ip1, jm1, jp1  
        real(prec) :: inv_4dx, inv_4dy
        real(prec) :: dudx, dudy
        real(prec) :: dvdx, dvdy 
        real(prec) :: duxdz_aa, duydz_aa
        real(prec) :: eps_sq, mu  

        real(prec), parameter :: epsilon_sq_0 = 1e-6_prec   ! [a^-1] Bueler and Brown (2009), Eq. 26
        
        nx    = size(ux,1)
        ny    = size(ux,2)

        inv_4dx = 1.0_prec / (4.0_prec*dx) 
        inv_4dy = 1.0_prec / (4.0_prec*dy) 

        ! Initialize viscosity to zero
        sigma_sq = 0.0 
        
        ! Loop over domain to calculate viscosity at each Aa node

        do j = 1, ny
        do i = 1, nx

            im1 = max(i-1,1) 
            ip1 = min(i+1,nx) 
            jm1 = max(j-1,1) 
            jp1 = min(j+1,ny) 
            
            ! 1. Calculate effective strain components from horizontal stretching

            ! Aa node
            dudx = (ux(i,j) - ux(im1,j))/dx
            dvdy = (uy(i,j) - uy(i,jm1))/dy

            ! Calculation of cross terms on central Aa nodes (symmetrical results)
            dudy = ((ux(i,jp1)   - ux(i,jm1))    &
                  + (ux(im1,jp1) - ux(im1,jm1))) * inv_4dx 
            dvdx = ((uy(ip1,j)   - uy(im1,j))    &
                  + (uy(ip1,jm1) - uy(im1,jm1))) * inv_4dy 

            ! 2. Calculate the total effective strain rate
            ! from Pollard and de Conto (2012), Eq. 6
            ! (Note: equation in text seems to have typo concerning cross terms)

            ! Avoid underflows 
            if (abs(dudx) .lt. tol_underflow) dudx = 0.0 
            if (abs(dvdy) .lt. tol_underflow) dvdy = 0.0 
            if (abs(dudy) .lt. tol_underflow) dudy = 0.0 
            if (abs(dvdx) .lt. tol_underflow) dvdx = 0.0 

            eps_sq = dudx**2 + dvdy**2 + dudx*dvdy + 0.25*(dudy+dvdx)**2 + epsilon_sq_0
            
            ! 3. Calculate the effective visocity (`eta` in Greve and Blatter, 2009)
            ! Pollard and de Conto (2012), Eqs. 2a/b and Eq. 4 (`visc=A**(-1/n)*mu*H_ice`)

            mu = 0.5_prec*(eps_sq)**((1.0_prec - n)/(2.0_prec*n))

            ! 4. Pollard and de Conto (2012), Eq. 7 on aa-nodes:
            ! Note: equation in text seems to have typo concerning cross terms
            sigma_sq(i,j) = (2.0_prec*mu * ATT_bar(i,j)**(-1.0_prec/n) )**2 * eps_sq

        end do 
        end do

        return
        
    end function calc_stress_eff_horizontal_squared

    subroutine calc_basal_stress(taub_acx,taub_acy,beta_acx,beta_acy,ux_b,uy_b)
        ! Calculate the basal stress resulting from sliding (friction times velocity)
        ! Note: calculated on ac-nodes.
        ! taub [Pa] 
        ! beta [Pa a m-1]
        ! u    [m a-1]
        ! taub = -beta*u 

        implicit none 

        real(prec), intent(OUT) :: taub_acx(:,:)   ! [Pa] Basal stress (acx nodes)
        real(prec), intent(OUT) :: taub_acy(:,:)   ! [Pa] Basal stress (acy nodes)
        real(prec), intent(IN)  :: beta_acx(:,:)   ! [Pa a m-1] Basal friction (acx nodes)
        real(prec), intent(IN)  :: beta_acy(:,:)   ! [Pa a m-1] Basal friction (acy nodes)
        real(prec), intent(IN)  :: ux_b(:,:)       ! [m a-1] Basal velocity (acx nodes)
        real(prec), intent(IN)  :: uy_b(:,:)       ! [m a-1] Basal velocity (acy nodes)
        
        real(prec), parameter :: tol = 1e-3_prec 

        ! Calculate basal stress 
        taub_acx = -beta_acx * ux_b 
        taub_acy = -beta_acy * uy_b 

        ! Avoid underflows
        where(abs(taub_acx) .lt. tol) taub_acx = 0.0_prec 
        where(abs(taub_acy) .lt. tol) taub_acy = 0.0_prec 
        
        return 

    end subroutine calc_basal_stress

end module velocity_hybrid_pd12
