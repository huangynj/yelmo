

module yelmo_io
    
    use ncio 
    
    use yelmo_defs 
    use yelmo_grid 

    implicit none

    private 
    public :: yelmo_write_init
    public :: yelmo_restart_write
    public :: yelmo_restart_read_1
    public :: yelmo_restart_read_2


contains

    subroutine yelmo_write_init(ylmo,filename,time_init,units)

        implicit none 

        type(yelmo_class), intent(IN) :: ylmo 
        character(len=*),  intent(IN) :: filename, units 
        real(prec),        intent(IN) :: time_init
        ! Initialize file by writing grid info
        call yelmo_grid_write(ylmo%grd,filename,create=.TRUE.)

        ! Initialize netcdf file and dimensions
        call nc_write_dim(filename,"month",  x=1,dx=1,nx=12,         units="month")
        call nc_write_dim(filename,"zeta",   x=ylmo%par%zeta_aa,     units="1")
        call nc_write_dim(filename,"zeta_ac",x=ylmo%par%zeta_ac,     units="1")
        call nc_write_dim(filename,"time",   x=time_init,dx=1.0_prec,nx=1,units=trim(units),unlimited=.TRUE.)

        ! Static information
        call nc_write(filename,"basins",  ylmo%bnd%basins, dim1="xc",dim2="yc",units="(0 - 8)",long_name="Hydrological basins")
        call nc_write(filename,"regions", ylmo%bnd%regions,dim1="xc",dim2="yc",units="(0 - 8)",long_name="Domain regions")
        
        return

    end subroutine yelmo_write_init 

    subroutine yelmo_restart_write(dom,filename,time)

        implicit none 

        type(yelmo_class), intent(IN) :: dom
        character(len=*),  intent(IN) :: filename 
        real(prec),        intent(IN) :: time 
        
        ! Local variables
        integer :: ncid 
        
        ! Write all yelmo data to file, so that it can be
        ! read later to restart a simulation.
        
        ! == Initialize netcdf file ==============================================

        call nc_create(filename)
        call nc_write_dim(filename,"xc",       x=dom%grd%xc*1e-3,       units="kilometers")
        call nc_write_dim(filename,"yc",       x=dom%grd%yc*1e-3,       units="kilometers")
        call nc_write_dim(filename,"zeta",     x=dom%par%zeta_aa,       units="1")
        call nc_write_dim(filename,"zeta_ac",  x=dom%par%zeta_ac,       units="1")
        call nc_write_dim(filename,"time",     x=time,dx=1.0_prec,nx=1, units="years ago")
 
        ! == Begin writing data ==============================================
        
        ! Open the file for writing
        call nc_open(filename,ncid,writable=.TRUE.)
        
        ! == ytopo variables ===
         call nc_write(filename,"H_ice",       dom%tpo%now%H_ice,      units="m",  dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"z_srf",       dom%tpo%now%z_srf,      units="m",  dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"dzsrfdt",     dom%tpo%now%dzsrfdt,    units="m/a",dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"dHicedt",     dom%tpo%now%dHicedt,    units="m/a",dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"bmb",         dom%tpo%now%bmb,        units="m/a",dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"mb_applied",  dom%tpo%now%mb_applied, units="m/a",dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"calv",        dom%tpo%now%calv,       units="m/a",dim1="xc",dim2="yc",ncid=ncid)
!mmr
!mmr-no         call nc_write(filename,"calv_mean",   dom%tpo%now%calv_mean,  units="m/a",dim1="xc",dim2="yc",ncid=ncid)
!mmr-no         call nc_write(filename,"calv_times",  dom%tpo%now%calv_times, units=" ",dim1="xc",dim2="yc",ncid=ncid)
!mmr
         call nc_write(filename,"dzsdx",       dom%tpo%now%dzsdx,      units="m/m",  dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"dzsdy",       dom%tpo%now%dzsdy,      units="m/m",  dim1="xc",dim2="yc",ncid=ncid)
!mmr
         call nc_write(filename,"dHicedx",     dom%tpo%now%dHicedx,    units="m/m",  dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"dHicedy",     dom%tpo%now%dHicedy,    units="m/m",  dim1="xc",dim2="yc",ncid=ncid)

         call nc_write(filename,"H_grnd",      dom%tpo%now%H_grnd,     units="b",dim1="xc",dim2="yc",ncid=ncid)
!mmr
         call nc_write(filename,"f_grnd",      dom%tpo%now%f_grnd,     units="1",dim1="xc",dim2="yc",ncid=ncid)
!mmr
         call nc_write(filename,"f_grnd_acx",  dom%tpo%now%f_grnd,     units="1",dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"f_grnd_acy",  dom%tpo%now%f_grnd,     units="1",dim1="xc",dim2="yc",ncid=ncid)
!mmr
         call nc_write(filename,"f_ice",       dom%tpo%now%f_ice,      units="1",dim1="xc",dim2="yc",ncid=ncid)
!mmr
         call nc_write(filename,"dist_margin", dom%tpo%now%dist_margin, units=" ",dim1="xc",dim2="yc",ncid=ncid)
         call nc_write(filename,"dist_grline", dom%tpo%now%dist_grline, units=" ",dim1="xc",dim2="yc",ncid=ncid)
!mmr
         call nc_write(filename,"mask_bed",    dom%tpo%now%mask_bed,    units="1",dim1="xc",dim2="yc",ncid=ncid)
!mmr-no         call nc_write(filename,"is_float",    dom%tpo%now%is_float,    units="1",dim1="xc",dim2="yc",ncid=ncid)
!mmr-no         call nc_write(filename,"is_grline",   dom%tpo%now%is_grline,   units="1",dim1="xc",dim2="yc",ncid=ncid)
!mmr-no         call nc_write(filename,"is_grz",      dom%tpo%now%is_grz,      units="1",dim1="xc",dim2="yc",ncid=ncid)
 
         ! == ydyn variables ===

!         ! ajr: to do !!!
! !         call nc_write(filename,"ux_i",    dom%dyn%now%Ux_i,units="m/a",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
! !         Call nc_write(filename,"uy_i",    dom%dyn%now%uy_i,units="m/a",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
! !         call nc_write(filename,"ux_i_bar",dom%dyn%now%ux_i_bar,units="m/a",dim1="xc",dim2="yc",ncid=ncid)
! !         Call nc_write(filename,"uy_i_bar",dom%dyn%now%uy_i_bar,units="m/a",dim1="xc",dim2="yc",ncid=ncid)
! !         call nc_write(filename,"ux_b",    dom%dyn%now%ux_b,units="m/a",dim1="xc",dim2="yc",ncid=ncid)
! !         call nc_write(filename,"uy_b",    dom%dyn%now%uy_b,units="m/a",dim1="xc",dim2="yc",ncid=ncid)
! !         call nc_write(filename,"ux_bar",  dom%dyn%now%ux_bar,units="m/a",dim1="xc",dim2="yc",ncid=ncid)
! !         call nc_write(filename,"uy_bar",  dom%dyn%now%uy_bar,units="m/a",dim1="xc",dim2="yc",ncid=ncid)

! !         call nc_write(filename,"ux",    dom%dyn%now%ux,units="m/a",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
! !         call nc_write(filename,"uy",    dom%dyn%now%uy,units="m/a",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
! !         call nc_write(filename,"uz",    dom%dyn%now%uz,units="m/a",dim1="xc",dim2="yc",dim3="zeta_ac",ncid=ncid)
        
! !         call nc_write(filename,"f_vbvs",    dom%dyn%now%f_vbvs,units="1",dim1="xc",dim2="yc",ncid=ncid)
        
! !         call nc_write(filename,"C_bed",  dom%dyn%now%C_bed,  units="?",dim1="xc",dim2="yc",ncid=ncid)
! !         call nc_write(filename,"N_eff",    dom%dyn%now%N_eff,    units="bar",dim1="xc",dim2="yc",ncid=ncid)
! !         call nc_write(filename,"beta_c",dom%dyn%now%beta_c,units="?",dim1="xc",dim2="yc",ncid=ncid)
        
! !         call nc_write(filename,"tau_b",  dom%dyn%now%tau_b,  units="?",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"ux_s",          dom%dyn%now%ux_s,     units="m/a",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"uy_s",          dom%dyn%now%uy_s,     units="m/a",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"uxy_s",         dom%dyn%now%uxy_s,    units="m/a",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"ux_i",          dom%dyn%now%ux_i,     units="m/a",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"uy_i",          dom%dyn%now%uy_i,     units="m/a",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"ux_i_bar",      dom%dyn%now%ux_i_bar, units="m/a",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"uy_i_bar",      dom%dyn%now%uy_i_bar, units="m/a",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"uxy_i_bar",     dom%dyn%now%uxy_i_bar,units="m/a",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"dd_ab",         dom%dyn%now%dd_ab,    units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"dd_ab_bar",     dom%dyn%now%dd_ab_bar,units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"sigma_horiz_sq",dom%dyn%now%sigma_horiz_sq,units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"lhs_x",         dom%dyn%now%lhs_x,         units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"lhs_y",         dom%dyn%now%lhs_y,         units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"lhs_xy",        dom%dyn%now%lhs_xy,        units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"duxdz",         dom%dyn%now%duxdz,     units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"duydz",         dom%dyn%now%duydz,     units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"duxdz_bar",     dom%dyn%now%duxdz_bar, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"duydz_bar",     dom%dyn%now%duydz_bar, units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"taud_acx",      dom%dyn%now%taud_acx, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"taud_acy",      dom%dyn%now%taud_acy, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"taud",          dom%dyn%now%taud,     units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"taub_acx",      dom%dyn%now%taub_acx, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"taub_acy",      dom%dyn%now%taub_acy, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"taub",          dom%dyn%now%taub,     units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"qq_acx",        dom%dyn%now%qq_acx,   units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"qq_acy",        dom%dyn%now%qq_acy,   units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"qq",            dom%dyn%now%qq,       units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"visc_eff",      dom%dyn%now%visc_eff,units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"N_eff",         dom%dyn%now%N_eff,    units="",dim1="xc",dim2="yc",ncid=ncid)       
        call nc_write(filename,"C_bed",         dom%dyn%now%C_bed,    units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"beta_acx",      dom%dyn%now%beta_acx, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"beta_acy",      dom%dyn%now%beta_acy, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"beta",          dom%dyn%now%beta,     units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"g_vbvs",        dom%dyn%now%f_vbvs,   units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"ssa_mask_acx",  dom%dyn%now%ssa_mask_acx, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"ssa_mask_acy",  dom%dyn%now%ssa_mask_acy, units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"gfa1",          dom%dyn%now%gfa1, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"gfa2",          dom%dyn%now%gfa2, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"gfb1",          dom%dyn%now%gfb1, units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"gfb2",          dom%dyn%now%gfb2, units="",dim1="xc",dim2="yc",ncid=ncid)
!mmr---------------------------------------------------------------------------------------------------------

!mmr---------------------------------------------------------------------------------------------------------
!         
!         ! == ymat variables === 
!         call nc_write(filename,"strn2D_dxx",dom%mat%now%strn2D%dxx,units="m/m",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"strn2D_dyy",dom%mat%now%strn2D%dyy,units="m/m",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"strn2D_dxy",dom%mat%now%strn2D%dxy,units="m/m",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"strn2D_de", dom%mat%now%strn2D%de, units="m/m",dim1="xc",dim2="yc",ncid=ncid)
        
!         call nc_write(filename,"strn_dxx",dom%mat%now%strn%dxx,units="m/m",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"strn_dyy",dom%mat%now%strn%dyy,units="m/m",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"strn_dxy",dom%mat%now%strn%dxy,units="m/m",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"strn_dxz",dom%mat%now%strn%dxz,units="m/m",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"strn_dyz",dom%mat%now%strn%dyz,units="m/m",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"strn_de", dom%mat%now%strn%de, units="m/m",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"strn_f_shear",dom%mat%now%strn%f_shear,units="1",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)

!         call nc_write(filename,"f_shear_bar",dom%mat%now%f_shear_bar,units="",dim1="xc",dim2="yc",ncid=ncid)

!         call nc_write(filename,"enh",      dom%mat%now%enh,         units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"enh_bar",  dom%mat%now%enh_bar,     units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"ATT",      dom%mat%now%ATT,         units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"ATT_bar",  dom%mat%now%ATT_bar,     units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"visc",     dom%mat%now%visc,        units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"visc_int", dom%mat%now%visc_int,    units="",dim1="xc",dim2="yc",ncid=ncid)
! 

        call nc_write(filename,"strn2D_dxx", dom%mat%now%strn2D%dxx,  units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"strn2D_dyy", dom%mat%now%strn2D%dyy,  units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"strn2D_dxy", dom%mat%now%strn2D%dxy,  units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"strn2D_de",  dom%mat%now%strn2D%de,   units="",dim1="xc",dim2="yc", ncid=ncid)
        
        call nc_write(filename,"strn_dxx",     dom%mat%now%strn%dxx,        units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"strn_dyy",     dom%mat%now%strn%dyy,        units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"strn_dxy",     dom%mat%now%strn%dxy,        units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"strn_dxz",     dom%mat%now%strn%dxz,        units="",dim1="xc",dim2="yc",dim3="zeta", ncid=ncid)
        call nc_write(filename,"strn_dyz",     dom%mat%now%strn%dyz,        units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"strn_de",      dom%mat%now%strn%de,         units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"strn_f_shear", dom%mat%now%strn%f_shear,    units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)

        call nc_write(filename,"enh",         dom%mat%now%enh,           units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"enh_bar",     dom%mat%now%enh_bar,       units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"ATT",         dom%mat%now%ATT,           units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"ATT_bar",     dom%mat%now%ATT_bar,       units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"visc",        dom%mat%now%visc,          units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
        call nc_write(filename,"visc_int",    dom%mat%now%visc_int,      units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"f_shear_bar", dom%mat%now%f_shear_bar,   units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"dep_time",    dom%mat%now%dep_time,      units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)    


!mmr------------------------------------------------------------------------------------------------------------------------------

!         ! == ytherm variables ===

!         call nc_write(filename,"T_ice",     dom%thrm%now%T_ice,     units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"T_pmp",     dom%thrm%now%T_pmp,     units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)
!         call nc_write(filename,"phid",      dom%thrm%now%phid,      units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"f_pmp",     dom%thrm%now%f_pmp,     units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"bmb_grnd",  dom%thrm%now%bmb_grnd,  units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"Q_b",       dom%thrm%now%Q_b,       units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"Q_strn",    dom%thrm%now%Q_strn,    units="",dim1="xc",dim2="yc",dim3="zeta", ncid=ncid)
!         call nc_write(filename,"T_rock",    dom%thrm%now%T_rock,    units="",dim1="xc",dim2="yc",dim3="sr",ncid=ncid)

        call nc_write(filename,"T_ice",       dom%thrm%now%T_ice,      units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)     
        call nc_write(filename,"enth_ice",    dom%thrm%now%enth_ice,   units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)     
        call nc_write(filename,"omega_ice",   dom%thrm%now%omega_ice,  units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)     
        call nc_write(filename,"T_pmp",       dom%thrm%now%T_pmp,      units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)     
        call nc_write(filename,"phid",        dom%thrm%now%phid,       units="",dim1="xc",dim2="yc",ncid=ncid)                 
        call nc_write(filename,"f_pmp",       dom%thrm%now%f_pmp,      units="",dim1="xc",dim2="yc",ncid=ncid)       
        call nc_write(filename,"bmb_grnd",    dom%thrm%now%bmb_grnd,   units="",dim1="xc",dim2="yc",ncid=ncid)    
        call nc_write(filename,"Q_strn",      dom%thrm%now%Q_strn,     units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)    
        call nc_write(filename,"Q_b",         dom%thrm%now%Q_b,        units="",dim1="xc",dim2="yc",ncid=ncid)         
        call nc_write(filename,"cp",          dom%thrm%now%cp,         units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)        
        call nc_write(filename,"kt",          dom%thrm%now%kt,         units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)        

        call nc_write(filename,"T_rock",      dom%thrm%now%T_rock,     units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)    
        call nc_write(filename,"dTdz_b",      dom%thrm%now%dTdz_b,     units="",dim1="xc",dim2="yc",ncid=ncid)      
        call nc_write(filename,"dTrdz_b",     dom%thrm%now%dTrdz_b,    units="",dim1="xc",dim2="yc",ncid=ncid)     
        call nc_write(filename,"T_prime_b",   dom%thrm%now%T_prime_b,  units="",dim1="xc",dim2="yc",ncid=ncid)   
        call nc_write(filename,"cts",         dom%thrm%now%cts,        units="",dim1="xc",dim2="yc",ncid=ncid)      
!mmr-no        call nc_write(filename,"T_all",       dom%thrm%now%T_all,      units="",dim1="xc",dim2="yc",dim3="zeta",ncid=ncid)

        
!         ! == ybound variables ===

!         call nc_write(filename,"z_bed",   dom%bnd%z_bed,   units="m",    dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"z_sl",    dom%bnd%z_sl,    units="m",    dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"H_sed",   dom%bnd%H_sed,   units="m",    dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"H_w",     dom%bnd%H_w,     units="m",    dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"smb",     dom%bnd%smb,     units="m/a",  dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"T_srf",   dom%bnd%T_srf,   units="K",    dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"bmb_shlf",dom%bnd%bmb_shlf,units="m/a",  dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"T_shlf",  dom%bnd%T_shlf,  units="K",    dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"Q_geo",   dom%bnd%Q_geo,   units="mW/m2",dim1="xc",dim2="yc",ncid=ncid)

!         call nc_write(filename,"basins",     dom%bnd%basins,     units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"basin_mask", dom%bnd%basin_mask, units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"regions",    dom%bnd%regions,    units="",dim1="xc",dim2="yc",ncid=ncid)
!         call nc_write(filename,"region_mask",dom%bnd%region_mask,units="",dim1="xc",dim2="yc",ncid=ncid)
        
        call nc_write(filename,"z_bed",       dom%bnd%z_bed,       units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"z_sl",        dom%bnd%z_sl,        units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"H_sed",       dom%bnd%H_sed,       units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"H_w",         dom%bnd%H_w,         units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"smb",         dom%bnd%smb,         units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"T_srf",       dom%bnd%T_srf,       units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"bmb_shlf",    dom%bnd%bmb_shlf,    units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"T_shlf",      dom%bnd%T_shlf,      units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"Q_geo",       dom%bnd%Q_geo,       units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"basins",      dom%bnd%basins,      units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"basin_mask",  dom%bnd%basin_mask,  units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"regions",     dom%bnd%regions,     units="",dim1="xc",dim2="yc",ncid=ncid)
        call nc_write(filename,"region_mask", dom%bnd%region_mask, units="",dim1="xc",dim2="yc",ncid=ncid)

        call nc_write(filename,"ice_allowed", dom%bnd%ice_allowed, units="",dim1="xc",dim2="yc",ncid=ncid)

        
!mmr------------------------------


        ! == ydata variables ===

        ! TO DO (not necessary for restart, but let's see...)

        ! Close the netcdf file
        call nc_close(ncid)

        ! Write summary 
        write(*,*) 
        write(*,*) "time = ", time, " : saved restart file: ", trim(filename)
        write(*,*) 

        return 

    end subroutine yelmo_restart_write 

    subroutine yelmo_restart_read_1(dom,filename,time)  
        ! Load yelmo variables from restart file: [tpo] 
        ! [dyn,therm,mat] variables loaded using yelmo_restart_read_2
        
        implicit none 

        type(yelmo_class), intent(INOUT) :: dom 
        character(len=*),  intent(IN)    :: filename 
        real(prec),        intent(IN)    :: time 
        
        ! Local variables
        integer :: ncid
        
        ! Read all yelmo data from file,
        ! in order to restart a simulation.
        
        ! Open the file for writing

!mmr--------------------------------------------------------------------------------------------------      

!mmr        call nc_open(filename,ncid,writable=.FALSE.)

        call nc_read(filename,"xc",ncid)
        call nc_read(filename,"yc",ncid)
        call nc_read(filename,"zeta",ncid)
        call nc_read(filename,"zeta_ac",ncid)
        call nc_read(filename,"time",ncid)

        call nc_open(filename,ncid,writable=.FALSE.)

         ! == ytopo variables ===

         ! call nc_read(filename,"H_ice",   dom%tpo%now%H_ice,   ncid=ncid)
        ! call nc_read(filename,"z_srf",   dom%tpo%now%z_srf,   ncid=ncid)
        ! call nc_read(filename,"dzsrfdt", dom%tpo%now%dzsrfdt, ncid=ncid)
        ! call nc_read(filename,"dHicedt", dom%tpo%now%dHicedt, ncid=ncid)
        ! call nc_read(filename,"bmb",     dom%tpo%now%bmb,     ncid=ncid)
        ! call nc_read(filename,"mb_applied",dom%tpo%now%mb_applied,ncid=ncid)
        ! call nc_read(filename,"calv",    dom%tpo%now%calv,    ncid=ncid)
        
        ! call nc_read(filename,"dzsdx",   dom%tpo%now%dzsdx,   ncid=ncid)
        ! call nc_read(filename,"dzsdy",   dom%tpo%now%dzsdy,   ncid=ncid)
        
        ! call nc_read(filename,"f_grnd",   dom%tpo%now%f_grnd,   ncid=ncid)
        ! call nc_read(filename,"f_ice",    dom%tpo%now%f_ice,    ncid=ncid)
        
        ! call nc_read(filename,"mask_bed", dom%tpo%now%mask_bed, ncid=ncid)
        ! call nc_read(filename,"is_float", dom%tpo%now%is_float, ncid=ncid)
        ! call nc_read(filename,"is_grline",dom%tpo%now%is_grline,ncid=ncid)
        ! call nc_read(filename,"is_grz",   dom%tpo%now%is_grz,   ncid=ncid)

         call nc_read(filename,"H_ice",       dom%tpo%now%H_ice)
         call nc_read(filename,"z_srf",       dom%tpo%now%z_srf)
         call nc_read(filename,"dzsrfdt",     dom%tpo%now%dzsrfdt)
         call nc_read(filename,"dHicedt",     dom%tpo%now%dHicedt)
         call nc_read(filename,"bmb",         dom%tpo%now%bmb)
         call nc_read(filename,"mb_applied",  dom%tpo%now%mb_applied)
         call nc_read(filename,"calv",        dom%tpo%now%calv)
!mmr
!mmr-no         call nc_read(filename,"calv_mean",   dom%tpo%now%calv_mean)
!mmr-no         call nc_read(filename,"calv_times",  dom%tpo%now%calv_times)
!mmr
         call nc_read(filename,"dzsdx",       dom%tpo%now%dzsdx)
         call nc_read(filename,"dzsdy",       dom%tpo%now%dzsdy)
!mmr
         call nc_read(filename,"dHicedx",     dom%tpo%now%dHicedx)
         call nc_read(filename,"dHicedy",     dom%tpo%now%dHicedy)

         call nc_read(filename,"H_grnd",      dom%tpo%now%H_grnd)
!mmr
         call nc_read(filename,"f_grnd",      dom%tpo%now%f_grnd)
!mmr
         call nc_read(filename,"f_grnd_acx",  dom%tpo%now%f_grnd)
         call nc_read(filename,"f_grnd_acy",  dom%tpo%now%f_grnd)
!mmr
         call nc_read(filename,"f_ice",       dom%tpo%now%f_ice)
!mmr
         call nc_read(filename,"dist_margin", dom%tpo%now%dist_margin)
         call nc_read(filename,"dist_grline", dom%tpo%now%dist_grline)
!mmr
         call nc_read(filename,"mask_bed",    dom%tpo%now%mask_bed)
!mmr-no         call nc_read(filename,"is_float",    dom%tpo%now%is_float)
!mmr-no         call nc_read(filename,"is_grline",   dom%tpo%now%is_grline)
!mmr-no         call nc_read(filename,"is_grz",      dom%tpo%now%is_grz)

! mmr --------------------------------------------------------------------------------------------------

        
        ! Close the netcdf file
        call nc_close(ncid)

!mmr
        dom%tpo%par%time = time
        dom%dyn%par%time = time 
!mmr

        ! Write summary 
        write(*,*) 
!mmr         write(*,*) "time = ", time, " : loaded restart file: ", trim(filename)
        write(*,*) "time = ", time, dom%tpo%par%time, dom%dyn%par%time, " : loaded restart file: ", trim(filename)
        write(*,*) 
        
        return 

    end subroutine yelmo_restart_read_1 


    subroutine yelmo_restart_read_2(dom,filename,time)
        ! Load yelmo variables from restart file: [dyn,therm,mat] 
        ! [tpo] variables loaded using yelmo_restart_read_1

        implicit none 

        type(yelmo_class), intent(INOUT) :: dom 
        character(len=*),  intent(IN)    :: filename 
        real(prec),        intent(IN)    :: time 
        
        ! Local variables
        integer :: ncid
        
        ! Read all yelmo data from file,
        ! in order to restart a simulation.
        
        ! Open the file for writing
        call nc_open(filename,ncid,writable=.FALSE.)
        
        ! == ydyn variables ===

        ! ajr: to do !!!
!         call nc_read(filename,"ux_sia",dom%dyn%now%ux_sia,ncid=ncid)
!         call nc_read(filename,"uy_sia",dom%dyn%now%uy_sia,ncid=ncid)
!         call nc_read(filename,"ux_ssa",dom%dyn%now%ux_ssa,ncid=ncid)
!         call nc_read(filename,"uy_ssa",dom%dyn%now%uy_ssa,ncid=ncid)
!         call nc_read(filename,"ux_bar",dom%dyn%now%ux_bar,ncid=ncid)
!         call nc_read(filename,"uy_bar",dom%dyn%now%uy_bar,ncid=ncid)
!         call nc_read(filename,"diff",  dom%dyn%now%diff,  ncid=ncid)
        
!         call nc_read(filename,"ux",    dom%dyn%now%ux,ncid=ncid)
!         call nc_read(filename,"uy",    dom%dyn%now%uy,ncid=ncid)
!         call nc_read(filename,"uz",    dom%dyn%now%uz,ncid=ncid)
        
!         call nc_read(filename,"f_ssa",     dom%dyn%now%f_ssa,     ncid=ncid)
!         call nc_read(filename,"f_ssa_mx",  dom%dyn%now%f_ssa_mx,  ncid=ncid)
!         call nc_read(filename,"f_ssa_my",  dom%dyn%now%f_ssa_my,  ncid=ncid)
!         call nc_read(filename,"ssa_active",dom%dyn%now%ssa_active,ncid=ncid)
        
!         call nc_read(filename,"f_vbvs",    dom%dyn%now%f_vbvs,    ncid=ncid)

!         call nc_read(filename,"N_eff",    dom%dyn%now%N_eff,    ncid=ncid)

!         call nc_read(filename,"beta",      dom%dyn%now%beta,      ncid=ncid)
!         call nc_read(filename,"beta_c",    dom%dyn%now%beta_c,    ncid=ncid)
        
!         call nc_read(filename,"tau_mx",  dom%dyn%now%tau_mx,      ncid=ncid)
!         call nc_read(filename,"tau_my",  dom%dyn%now%tau_my,      ncid=ncid)
!mmr 
!        ! == ymat variables ===
!        call nc_read(filename,"strn2D_dxx",dom%mat%now%strn2D%dxx,ncid=ncid)
!        call nc_read(filename,"strn2D_dyy",dom%mat%now%strn2D%dyy,ncid=ncid)
!        call nc_read(filename,"strn2D_dxy",dom%mat%now%strn2D%dxy,ncid=ncid)
!        call nc_read(filename,"strn2D_de", dom%mat%now%strn2D%de, ncid=ncid)
!        
!        call nc_read(filename,"strn_dxx",dom%mat%now%strn%dxx,        ncid=ncid)
!        call nc_read(filename,"strn_dyy",dom%mat%now%strn%dyy,        ncid=ncid)
!        call nc_read(filename,"strn_dxy",dom%mat%now%strn%dxy,        ncid=ncid)
!        call nc_read(filename,"strn_dxz",dom%mat%now%strn%dxz,        ncid=ncid)
!        call nc_read(filename,"strn_dyz",dom%mat%now%strn%dyz,        ncid=ncid)
!        call nc_read(filename,"strn_de", dom%mat%now%strn%de,         ncid=ncid)
!        call nc_read(filename,"strn_f_shear",dom%mat%now%strn%f_shear,ncid=ncid)
!
!        call nc_read(filename,"f_shear_bar",dom%mat%now%f_shear_bar,  ncid=ncid)
!
!        call nc_read(filename,"enh",      dom%mat%now%enh,            ncid=ncid)
!        call nc_read(filename,"enh_bar",  dom%mat%now%enh_bar,        ncid=ncid)
!        call nc_read(filename,"ATT",      dom%mat%now%ATT,            ncid=ncid)
!        call nc_read(filename,"ATT_bar",  dom%mat%now%ATT_bar,        ncid=ncid)
!        call nc_read(filename,"visc",     dom%mat%now%visc,           ncid=ncid)
!        call nc_read(filename,"visc_int", dom%mat%now%visc_int,       ncid=ncid)
!        
!        ! == ytherm variables ===
!        call nc_read(filename,"T_ice",     dom%thrm%now%T_ice,        ncid=ncid)
!        call nc_read(filename,"T_pmp",     dom%thrm%now%T_pmp,        ncid=ncid)
!        call nc_read(filename,"phid",      dom%thrm%now%phid,         ncid=ncid)
!        call nc_read(filename,"f_pmp",     dom%thrm%now%f_pmp,        ncid=ncid)
!        call nc_read(filename,"bmb_grnd",  dom%thrm%now%bmb_grnd,     ncid=ncid)
!        call nc_read(filename,"Q_b",       dom%thrm%now%Q_b,          ncid=ncid)
!        call nc_read(filename,"Q_strn",    dom%thrm%now%Q_strn,       ncid=ncid)
!        call nc_read(filename,"T_rock",    dom%thrm%now%T_rock,       ncid=ncid)
!        
!        ! == ybound variables ===
!        call nc_read(filename,"z_bed",   dom%bnd%z_bed,               ncid=ncid)
!        call nc_read(filename,"z_sl",    dom%bnd%z_sl,                ncid=ncid)
!        call nc_read(filename,"H_sed",   dom%bnd%H_sed,               ncid=ncid)
!        call nc_read(filename,"H_w",     dom%bnd%H_w,                 ncid=ncid)
!        call nc_read(filename,"smb",     dom%bnd%smb,                 ncid=ncid)
!        call nc_read(filename,"T_srf",   dom%bnd%T_srf,               ncid=ncid)
!        call nc_read(filename,"bmb_shlf",dom%bnd%bmb_shlf,            ncid=ncid)
!        call nc_read(filename,"T_shlf",  dom%bnd%T_shlf,              ncid=ncid)
!        call nc_read(filename,"Q_geo",   dom%bnd%Q_geo,               ncid=ncid)
!
!        call nc_read(filename,"basins",     dom%bnd%basins,           ncid=ncid)
!        call nc_read(filename,"basin_mask", dom%bnd%basin_mask,       ncid=ncid)
!        call nc_read(filename,"regions",    dom%bnd%regions,          ncid=ncid)
!        call nc_read(filename,"region_mask",dom%bnd%region_mask,      ncid=ncid)
!
!
!
       ! == ydyn variables ===

        call nc_read(filename,"ux_s",          dom%dyn%now%ux_s)
        call nc_read(filename,"uy_s",          dom%dyn%now%uy_s)
        call nc_read(filename,"uxy_s",         dom%dyn%now%uxy_s)

        call nc_read(filename,"ux_i",          dom%dyn%now%ux_i)
        call nc_read(filename,"uy_i",          dom%dyn%now%uy_i)
        call nc_read(filename,"ux_i_bar",      dom%dyn%now%ux_i_bar)
        call nc_read(filename,"uy_i_bar",      dom%dyn%now%uy_i_bar)
        call nc_read(filename,"uxy_i_bar",     dom%dyn%now%uxy_i_bar)

        call nc_read(filename,"dd_ab",         dom%dyn%now%dd_ab)
        call nc_read(filename,"dd_ab_bar",     dom%dyn%now%dd_ab_bar)

        call nc_read(filename,"sigma_horiz_sq",dom%dyn%now%sigma_horiz_sq)
        call nc_read(filename,"lhs_x",         dom%dyn%now%lhs_x)
        call nc_read(filename,"lhs_y",         dom%dyn%now%lhs_y)
        call nc_read(filename,"lhs_xy",        dom%dyn%now%lhs_xy)

        call nc_read(filename,"duxdz",         dom%dyn%now%duxdz)
        call nc_read(filename,"duydz",         dom%dyn%now%duydz)
        call nc_read(filename,"duxdz_bar",     dom%dyn%now%duxdz_bar)
        call nc_read(filename,"duydz_bar",     dom%dyn%now%duydz_bar)

        call nc_read(filename,"taud_acx",      dom%dyn%now%taud_acx)
        call nc_read(filename,"taud_acy",      dom%dyn%now%taud_acy)
        call nc_read(filename,"taud",          dom%dyn%now%taud)

        call nc_read(filename,"taub_acx",      dom%dyn%now%taub_acx)
        call nc_read(filename,"taub_acy",      dom%dyn%now%taub_acy)
        call nc_read(filename,"taub",          dom%dyn%now%taub)

        call nc_read(filename,"qq_acx",        dom%dyn%now%qq_acx)
        call nc_read(filename,"qq_acy",        dom%dyn%now%qq_acy)
        call nc_read(filename,"qq",            dom%dyn%now%qq)

        call nc_read(filename,"visc_eff",      dom%dyn%now%visc_eff)

        call nc_read(filename,"N_eff",         dom%dyn%now%N_eff)       
        call nc_read(filename,"C_bed",         dom%dyn%now%C_bed)
        call nc_read(filename,"beta_acx",      dom%dyn%now%beta_acx)
        call nc_read(filename,"beta_acy",      dom%dyn%now%beta_acy)
        call nc_read(filename,"beta",          dom%dyn%now%beta)

        call nc_read(filename,"g_vbvs",        dom%dyn%now%f_vbvs)

        call nc_read(filename,"ssa_mask_acx",  dom%dyn%now%ssa_mask_acx)
        call nc_read(filename,"ssa_mask_acy",  dom%dyn%now%ssa_mask_acy)

        call nc_read(filename,"gfa1",          dom%dyn%now%gfa1)
        call nc_read(filename,"gfa2",          dom%dyn%now%gfa2)
        call nc_read(filename,"gfb1",          dom%dyn%now%gfb1)
        call nc_read(filename,"gfb2",          dom%dyn%now%gfb2)


        call nc_read(filename,"strn2D_dxx", dom%mat%now%strn2D%dxx)
        call nc_read(filename,"strn2D_dyy", dom%mat%now%strn2D%dyy)
        call nc_read(filename,"strn2D_dxy", dom%mat%now%strn2D%dxy)
        call nc_read(filename,"strn2D_de",  dom%mat%now%strn2D%de)
        
        call nc_read(filename,"strn_dxx",     dom%mat%now%strn%dxx)
        call nc_read(filename,"strn_dyy",     dom%mat%now%strn%dyy)
        call nc_read(filename,"strn_dxy",     dom%mat%now%strn%dxy)
        call nc_read(filename,"strn_dxz",     dom%mat%now%strn%dxz)
        call nc_read(filename,"strn_dyz",     dom%mat%now%strn%dyz)
        call nc_read(filename,"strn_de",      dom%mat%now%strn%de)
        call nc_read(filename,"strn_f_shear", dom%mat%now%strn%f_shear)

        call nc_read(filename,"enh",         dom%mat%now%enh)
        call nc_read(filename,"enh_bar",     dom%mat%now%enh_bar)
        call nc_read(filename,"ATT",         dom%mat%now%ATT)
        call nc_read(filename,"ATT_bar",     dom%mat%now%ATT_bar)
        call nc_read(filename,"visc",        dom%mat%now%visc)
        call nc_read(filename,"visc_int",    dom%mat%now%visc_int)

        call nc_read(filename,"f_shear_bar", dom%mat%now%f_shear_bar)

        call nc_read(filename,"dep_time",    dom%mat%now%dep_time)


         ! == ytherm variables ===


        call nc_read(filename,"T_ice",       dom%thrm%now%T_ice)   
        call nc_read(filename,"enth_ice",    dom%thrm%now%enth_ice)  
        call nc_read(filename,"omega_ice",   dom%thrm%now%omega_ice)
        call nc_read(filename,"T_pmp",       dom%thrm%now%T_pmp)
        call nc_read(filename,"phid",        dom%thrm%now%phid) 
        call nc_read(filename,"f_pmp",       dom%thrm%now%f_pmp)
        call nc_read(filename,"bmb_grnd",    dom%thrm%now%bmb_grnd)   
        call nc_read(filename,"Q_strn",      dom%thrm%now%Q_strn)     
        call nc_read(filename,"Q_b",         dom%thrm%now%Q_b)        
        call nc_read(filename,"cp",          dom%thrm%now%cp)
        call nc_read(filename,"kt",          dom%thrm%now%kt)     

        call nc_read(filename,"T_rock",      dom%thrm%now%T_rock)    
        call nc_read(filename,"dTdz_b",      dom%thrm%now%dTdz_b)    
        call nc_read(filename,"dTrdz_b",     dom%thrm%now%dTrdz_b)   
        call nc_read(filename,"T_prime_b",   dom%thrm%now%T_prime_b) 
        call nc_read(filename,"cts",         dom%thrm%now%cts)      
!mmr-no        call nc_read(filename,"T_all",       dom%thrm%now%T_all) 

        
        ! == ybound variables ===

        call nc_read(filename,"z_bed",       dom%bnd%z_bed)
        call nc_read(filename,"z_sl",        dom%bnd%z_sl)
        call nc_read(filename,"H_sed",       dom%bnd%H_sed)
        call nc_read(filename,"H_w",         dom%bnd%H_w)
        call nc_read(filename,"smb",         dom%bnd%smb)
        call nc_read(filename,"T_srf",       dom%bnd%T_srf)
        call nc_read(filename,"bmb_shlf",    dom%bnd%bmb_shlf)
        call nc_read(filename,"T_shlf",      dom%bnd%T_shlf)
        call nc_read(filename,"Q_geo",       dom%bnd%Q_geo)

        call nc_read(filename,"basins",      dom%bnd%basins)
        call nc_read(filename,"basin_mask",  dom%bnd%basin_mask)
        call nc_read(filename,"regions",     dom%bnd%regions)
        call nc_read(filename,"region_mask", dom%bnd%region_mask)

        call nc_read(filename,"ice_allowed", dom%bnd%ice_allowed)
   
!mmr-------------------------------------------------------
!        ! Close the netcdf file
        call nc_close(ncid)

        ! Write summary 

!mmr
        dom%thrm%par%time = time
        dom%mat%par%time = time
!mmr

        write(*,*) 
!mmr        write(*,*) "time = ", time, " : loaded restart file: ", trim(filename)
        write(*,*) "time = ", time, dom%thrm%par%time, dom%mat%par%time, " : loaded restart file: ", trim(filename)
        write(*,*) 
        
        return 

    end subroutine yelmo_restart_read_2 
    

end module yelmo_io 


