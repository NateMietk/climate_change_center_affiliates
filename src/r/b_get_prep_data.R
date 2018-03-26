# Download and import CONUS states
# Download will only happen once as long as the file exists
if (!exists("usa_shp")){
  usa_shp <- load_data(url = "https://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip",
                       dir = us_prefix,
                       layer = "cb_2016_us_state_20m",
                       outname = "usa") %>%
    sf::st_transform(p4string_ea) %>%
    dplyr::filter(!STUSPS %in% c("HI", "AK", "PR"))
  
  st_write(usa_shp, file.path('data', 'partners', 'conus.shp'))
  
  college_states <- usa_shp %>%
    dplyr::filter(STUSPS %in% c("MT", "ND", "SD", 'WY', 'CO', 'NE', 'KS'))
  st_write(college_states, file.path('data', 'partners', 'college_states.shp'))
  
}

# Download and import the all college/universities shapefile
# Download will only happen once as long as the file exists
# https://www.sciencebase.gov/catalog/item/4f4e4acee4b07f02db67fb39
colleges <- st_read(file.path(colleges_dir, 'CollegesUniversities.shp')) %>%
  sf::st_transform(st_crs(usa_shp)) %>%
  st_intersection(., usa_shp) %>%
  dplyr::filter(STUSPS %in% c("MT", "ND", "SD", 'CO', 'NE', 'KS')) %>%
  dplyr::filter(NAME %in% c('The University of Montana',
                            'University of Colorado at Boulder',
                            'South Dakota State University')) %>%
  dplyr::select(NAME)

csp <- tibble(NAME = c('Conservation Science Partners', 'Wildlife Conservation Society'), 
              LATITUDE = c(as.numeric(40.587294), as.numeric(45.677274)),
              LONGITUDE = c(as.numeric(-105.075661), as.numeric(-111.028494))) %>%
  sf::st_as_sf(coords = c("LONGITUDE","LATITUDE")) %>% 
  sf::st_set_crs("+proj=longlat +ellps=WGS84 +datum=WGS84") %>%
  sf::st_transform(st_crs(usa_shp))

partners <- rbind(colleges, csp)

st_write(partners, file.path('data', 'partners', 'partners.shp'), delete_layer=TRUE)

#
college_erase <- st_buffer(college_states, 110000) %>%
  st_difference(., usa_shp) %>%
  st_union()

college_states_ll_sm <- college_erase %>%
  st_transform("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

college_states_ll <- college_states %>%
  st_transform("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

rky_mtns <- st_read("data/raw/na_cec_eco_l1/rocky_mnts_dis.shp") %>%
  st_transform(st_crs(college_states)) %>%
  st_intersection(., st_union(college_states))

sm <- raster('data/raw/SoilMoistureChange_2035-2064MINUS1971-2000_CONUS_rcp85_CESM_LargeENSM_40mem_JJA.nc',
             varname = "sm_change") %>%
  shift(., x = -360) %>%
  mask(as(college_states_ll_sm, 'Spatial')) %>%
  projectRaster(., crs = p4string_ea, res = 100000, method="bilinear") %>%
  disaggregate(., fact = 100) %>%
  crop(., as(college_erase, 'Spatial')) %>%
  mask(., as(college_states, 'Spatial')) %>%
  crop(., as(college_states, 'Spatial')) 

writeRaster(sm, 'data/raw/sm_change_ea.tif', overwrite = TRUE)

sm_colr <- colorRampPalette(rev(brewer.pal(9, 'YlOrBr')))

sm_levelplot <- levelplot(sm,
                           margin = FALSE,                       
                           colorkey = list(
                             space = 'right',                   
                             labels = list(at = seq(0, -10, by = -1.5), font = 4),
                             axis.line = list(col='black')       
                           ),    
                           par.settings = list(
                             axis.line = list(col = 'transparent') 
                           ),
                           scales = list(draw = FALSE),            
                           col.regions = sm_colr,                   # colour ramp
                           at = seq(0, -10, by = -1.5),
                           panel=panel.levelplot.raster) +           # colour ramp breaks
  layer(sp.polygons(as(rky_mtns, 'Spatial'), lwd = 2)) +           # colour ramp breaks
  layer(sp.polygons(as(st_union(college_states), 'Spatial'), lwd = 2)) 

pdf("maps/sm_map.pdf", height = 7 * 0.707, width = 6)  #0.707 is a convenient aspect.ratio
sm_levelplot
dev.off()

leri_07 <- raster('data/raw/LERI_07mn_20171001.nc',
             varname = "leri") %>%
  crop(as(college_states_ll, 'Spatial')) %>%
  mask(as(college_states_ll, 'Spatial')) %>%
  projectRaster(., crs = p4string_ea, res = 1000, method="bilinear") %>%
  crop(as(college_states, 'Spatial')) %>%
  mask(as(college_states, 'Spatial'))

quants <- quantile(leri_07, probs = c(seq(0,1, by = 0.05)))

reclass_df <- c(-57, 3.636363, 5,
                3.636363, 5.992209, 10,
                5.992209, 9.090908, 15,
                9.090908, 13.380621, 20,
                13.380621, 16.272638, 25,
                16.272638, 20.000000, 30, 
                20.000000, 24.903455, 35, 
                24.903455, 28.334071, 40, 
                28.334071, 31.982461, 45, 
                31.982461, 36.363632, 50, 
                36.363632, 41.069741, 55,
                41.069741, 45.255715, 60, 
                45.255715, 49.626894, 65,
                49.626894, 54.215156, 70, 
                54.215156, 59.488028, 75, 
                59.488028, 65.832379, 80,
                65.832379, 73.716715, 85,
                73.716715, 82.343080, 90,
                82.343080, 90.909088, 95,
                90.909088, 97, 100)
leri_reclass <- reclassify(leri_07, reclass_df)

writeRaster(leri_07, 'data/raw/leri_07.tif', overwrite = TRUE)
writeRaster(leri_07, 'data/raw/leri_reclass.tif', overwrite = TRUE)

leri_colr <- colorRampPalette(brewer.pal(9, 'RdYlBu'))

leri_levelplot <- levelplot(leri_reclass,
                           margin = FALSE,                       
                           colorkey = list(
                             space = 'right',                   
                             labels = list(at = seq(0,100, by = 10), font = 4),
                             axis.line = list(col='black')       
                           ),    
                           par.settings = list(
                             axis.line = list(col = 'transparent') 
                           ),
                           scales = list(draw = FALSE),            
                           col.regions = leri_colr,                   # colour ramp
                           at = seq(0,100, by = 10),
                           panel=panel.levelplot.raster) +           # colour ramp breaks
  layer(sp.polygons(as(rky_mtns, 'Spatial'), lwd = 2)) +           # colour ramp breaks
  layer(sp.polygons(as(st_union(college_states), 'Spatial'), lwd=2)) 
                           
pdf("maps/leri_reclass.pdf", height = 7 * 0.707, width = 6)  #0.707 is a convenient aspect.ratio
rst_levelplot
dev.off()


