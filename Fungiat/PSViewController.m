//
//  PSViewController.m
//  Fungiat
//
//  Created by Pietro Sacco on 23.11.13.
//  Copyright (c) 2013 Pietro Sacco. All rights reserved.
//

#import "PSViewController.h"

#define STARTTEXT @"Inizio"
#define STOPTEXT  @"Fine"

#pragma mark -

@interface PSViewController ()

@property (nonatomic) BOOL isTracking;
@property (nonatomic) BOOL isFirstTime;
@property (nonatomic) NSUInteger currentMapType;
@property (nonatomic) NSMutableArray *userLocations;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MKPolyline *pathOverlay;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *getBackButton;

- (void)trackUserLocation:(MKUserLocation *)userLocation;
- (void)zoomOnUserLocation;
- (void)placeStartPin;
- (void)placeStopPin;
- (void)updatePathOverlay;

- (IBAction)startStopButtonAction:(id)sender;
- (IBAction)mapButtonAction:(id)sender;
- (IBAction)getBackButtonAction:(id)sender;


@end

#pragma mark 

@implementation PSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _userLocations = [[NSMutableArray alloc] initWithCapacity:100];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = 2.0;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    _isFirstTime = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Private methods

- (void)trackUserLocation:(MKUserLocation *)userLocation
{
    [_userLocations addObject:userLocation];
}

- (void)zoomOnUserLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = _mapView.userLocation.coordinate;
    mapRegion.span = MKCoordinateSpanMake(0.00045, 0.0045);
    [_mapView setRegion:mapRegion animated:YES];
}

- (void)placeStartPin
{
    // Remove old pins first
    [_mapView removeAnnotations:_mapView.annotations];

    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = _mapView.userLocation.coordinate;
    //annotation.coordinate = [(CLLocation *)_userLocations.firstObject coordinate];
    annotation.title = STARTTEXT;
    
    [_mapView addAnnotation:annotation];
}

- (void)placeStopPin
{
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = [(CLLocation *)_userLocations.lastObject coordinate];
    annotation.title = STOPTEXT;
    
    [_mapView addAnnotation:annotation];
}

- (void)updatePathOverlay
{
    [_mapView removeOverlay:_pathOverlay];
    
    CLLocationCoordinate2D *coordinateArray = malloc(sizeof(CLLocationCoordinate2D) * _userLocations.count);
    
    int caIndex = 0;
    for (CLLocation *loc in _userLocations) {
        coordinateArray[caIndex] = loc.coordinate;
        caIndex++;
    }
    
    _pathOverlay = [MKPolyline polylineWithCoordinates:coordinateArray count:_userLocations.count];
    
    free(coordinateArray);
    
    [_mapView addOverlay:_pathOverlay];
}


#pragma mark - IBActions

- (IBAction)startStopButtonAction:(UIBarButtonItem *)sender
{
    _isTracking = !_isTracking;
    if (_isTracking) {
        [_userLocations removeAllObjects];
        [sender setTitle:@"Stop" ];
        [_locationManager startUpdatingLocation];
        [self placeStartPin];
        [_getBackButton setEnabled:NO];
        [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        [sender setTitle:@"Start"];
        [_locationManager stopUpdatingLocation];
        [self placeStopPin];
        [_getBackButton setEnabled:YES];
        [_mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }
}

- (IBAction)mapButtonAction:(id)sender
{
    _currentMapType += 1;
    _mapView.mapType = _currentMapType % 3;
}

- (IBAction)getBackButtonAction:(id)sender
{
    [_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
}


#pragma mark - MKMapView Delegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (_isFirstTime) {
        MKCoordinateRegion mapRegion;
        mapRegion.center = _mapView.userLocation.coordinate;
        mapRegion.span = MKCoordinateSpanMake(0.1, 0.1);
        [_mapView setRegion:mapRegion animated:YES];
        _isFirstTime = NO;
    }
    if (_isTracking) {
        //[self zoomOnUserLocation];
    }
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation.title isEqualToString:STARTTEXT]) {
        MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        pinView.canShowCallout = YES;
        pinView.animatesDrop = YES;
        pinView.pinColor = MKPinAnnotationColorGreen;
        return pinView;
    } else if ([annotation.title isEqualToString:STOPTEXT]) {
        MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        pinView.canShowCallout = YES;
        pinView.animatesDrop = YES;
        //pinView.pinColor = MKPinAnnotationColorGreen;
        return pinView;
    }
    
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:route];
        routeRenderer.strokeColor = [UIColor blueColor];
        routeRenderer.alpha = 0.5;
        routeRenderer.lineWidth = 6.0;
        return routeRenderer;
    }
    else return nil;
}


#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [_userLocations addObjectsFromArray:locations];
    [self updatePathOverlay];
}

@end
