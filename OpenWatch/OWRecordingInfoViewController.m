//
//  OWRecordingInfoViewController.m
//  OpenWatch
//
//  Created by Christopher Ballinger on 11/26/12.
//  Copyright (c) 2012 OpenWatch FPC. All rights reserved.
//

#import "OWRecordingInfoViewController.h"
#import "OWStrings.h"
#import "OWCaptureAPIClient.h"
#import "OWAccountAPIClient.h"
#import "OWMapAnnotation.h"
#import "OWRecordingController.h"
#import "OWTagEditViewController.h"
#import "OWUtilities.h"
#import "OWTallyView.h"
#import "UIImageView+AFNetworking.h"
#import "OWShareController.h"
#import "QuartzCore/CALayer.h"

#define PADDING 10.0f

@interface OWRecordingInfoViewController ()
@end

@implementation OWRecordingInfoViewController
@synthesize recordingID, mapView, moviePlayer, centerCoordinate, scrollView;
@synthesize titleLabel, segmentedControl;
@synthesize infoView, descriptionTextView, profileImageView, tallyView;
@synthesize usernameLabel;

- (id) init {
    if (self = [super init]) {
        [self setupScrollView];
        [self setupMapView];
        [self setupMoviePlayer];
        [self setupSegmentedControl];
        [self setupDescriptionView];
        [self setupInfoView];
        [self setupSharing];
        self.title = INFO_STRING;
    }
    return self;
}

- (void) shareButtonPressed:(id)sender {
    [[OWShareController sharedInstance] shareRecordingID:recordingID fromViewController:self];
}

- (void) setupSharing {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:SHARE_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(shareButtonPressed:)];
}

- (void) setupInfoView {
    self.infoView = [[UIView alloc] init];
    [self.scrollView addSubview:infoView];
    
    self.titleLabel = [[UILabel alloc] init];
    [self.infoView addSubview:titleLabel];
    [OWUtilities styleLabel:titleLabel];
    
    self.profileImageView = [[UIImageView alloc] init];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    /*profileImageView.layer.shadowColor = [UIColor blackColor].CGColor;
    profileImageView.layer.shadowOffset = CGSizeMake(0, 1);
    profileImageView.layer.shadowOpacity = 1;
    profileImageView.layer.shadowRadius = 3.0;
     */
    profileImageView.layer.cornerRadius = 5;
    profileImageView.clipsToBounds = YES;
    [self.infoView addSubview:profileImageView];
    
    self.usernameLabel = [[UILabel alloc] init];
    [self.infoView addSubview:usernameLabel];
    [OWUtilities styleLabel:usernameLabel];
    
    CGFloat width = 125.0f;
    CGFloat height = 20.0f;
    self.tallyView = [[OWTallyView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [self.infoView addSubview:tallyView];
}

- (void) setupDescriptionView {
    self.descriptionTextView = [[UITextView alloc] init];
    self.descriptionTextView.backgroundColor = [UIColor clearColor];
    self.descriptionTextView.editable = NO;
    self.descriptionTextView.font = [UIFont systemFontOfSize:16.0f];
    [self.scrollView addSubview:descriptionTextView];
}

- (void) setupMoviePlayer {
    self.moviePlayer = [[MPMoviePlayerController alloc] init];
    [self.view addSubview:moviePlayer.view];
}

- (void) setupSegmentedControl {
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[INFO_STRING, DESCRIPTION_STRING, MAP_STRING]];
    self.segmentedControl.selectedSegmentIndex = 0;
    //segmentedControl.segmentedControlStyle = 7;
    [self.view addSubview:segmentedControl];
    [segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void) segmentedControlValueChanged:(id)sender {
    CGPoint offset = CGPointMake(self.segmentedControl.selectedSegmentIndex * self.view.frame.size.width, 0);
    [scrollView setContentOffset:offset animated:YES];
}

- (void) setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.scrollEnabled = NO; // why doesnt this work?
    //self.scrollView.userInteractionEnabled = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;
    [self.view addSubview:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)theScrollView {
    self.segmentedControl.selectedSegmentIndex = self.scrollView.contentOffset.x / self.view.frame.size.width;
}

- (void) setupMapView {
    if (mapView) {
        [mapView removeFromSuperview];
    }
    self.mapView = [[MKMapView alloc] init];
    mapView.delegate = self;
    [self.scrollView addSubview:mapView];
}




- (MKAnnotationView*) mapView:(MKMapView *)theMapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *pinReuseIdentifier = @"pinReuseIdentifier";
    OWMapAnnotation *mapAnnotation = (OWMapAnnotation*)annotation;
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pinReuseIdentifier];
    if (!pinView) {
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:mapAnnotation reuseIdentifier:pinReuseIdentifier];
    }
    if (mapAnnotation.isStartLocation) {
        pinView.pinColor = MKPinAnnotationColorGreen;
    } else {
        pinView.pinColor = MKPinAnnotationColorRed;
    }
    return pinView;
}

- (void) refreshFrames {
    CGFloat moviePlayerYOrigin = 0.0f;
    CGFloat moviePlayerHeight = 180.0f;
    CGFloat frameWidth = self.view.frame.size.width;
    CGFloat frameHeight = self.view.frame.size.height;
    moviePlayer.view.frame = CGRectMake(0, moviePlayerYOrigin, frameWidth, moviePlayerHeight);
    self.segmentedControl.frame = CGRectMake(0, moviePlayerHeight, frameWidth , 40.0f);
    CGFloat scrollViewYOrigin = [OWUtilities bottomOfView:segmentedControl];
    CGFloat scrollViewHeight = frameHeight-scrollViewYOrigin;
    self.scrollView.frame = CGRectMake(0, scrollViewYOrigin, frameWidth, scrollViewHeight);
    self.scrollView.contentSize = CGSizeMake(frameWidth * 3, scrollViewHeight);
    
    self.infoView.frame = CGRectMake(0, 0, frameWidth, scrollViewHeight);
    self.descriptionTextView.frame = CGRectMake(frameWidth, 0, frameWidth, scrollViewHeight);
    self.mapView.frame = CGRectMake(frameWidth*2, 0, frameWidth, scrollViewHeight);
    [self setFramesForInfoView];
}

- (void) setFramesForInfoView {
    self.profileImageView.frame = CGRectMake(30, 30, 100, 100);
    self.usernameLabel.frame = CGRectMake(30, [OWUtilities bottomOfView:profileImageView], 100, 40);
    
    self.titleLabel.frame = CGRectMake([OWUtilities rightOfView:profileImageView] + PADDING, 50, 100, 50);
    self.tallyView.frame = CGRectMake([OWUtilities rightOfView:profileImageView] + PADDING, [OWUtilities bottomOfView:titleLabel], self.tallyView.frame.size.width, self.tallyView.frame.size.height);
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshFrames];
    [TestFlight passCheckpoint:VIEW_RECORDING_CHECKPOINT];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self resignFirstResponder];
    [moviePlayer stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (CLLocationCoordinate2DIsValid(centerCoordinate)) {
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(centerCoordinate, 1000, 1000) animated:YES];
    }
    [moviePlayer play];
}

- (void) setRecordingID:(NSManagedObjectID *)newRecordingID {
    recordingID = newRecordingID;

    OWManagedRecording *recording = [OWRecordingController recordingForObjectID:recordingID];
    
    [self refreshFields];
    
    [[OWAccountAPIClient sharedClient] getRecordingWithUUID:recording.uuid success:^(NSManagedObjectID *recordingObjectID) {
        OWManagedRecording *remoteRecording = [OWRecordingController recordingForObjectID:recordingObjectID];
        [[OWAccountAPIClient sharedClient] hitRecording:remoteRecording.objectID hitType:@"view"];
        self.moviePlayer.contentURL = [NSURL URLWithString:[remoteRecording remoteVideoURL]];
        [moviePlayer prepareToPlay];
        [self refreshMapParameters];
        [self refreshFields];
        [self refreshFrames];
        [TestFlight passCheckpoint:VIEW_RECORDING_ID_CHECKPOINT([remoteRecording.serverID intValue])];
    } failure:^(NSString *reason) {
        NSLog(@"failure to fetch recording details: %@", reason);
    }];
    


}


- (void) refreshMapParameters {
    OWLocalRecording *recording = [OWRecordingController recordingForObjectID:self.recordingID];
    double lat = 0.0f;
    double lon = 0.0f;
    CLLocation *start = recording.startLocation;
    CLLocation *end = recording.endLocation;
    if (start) {
        lat = start.coordinate.latitude;
        lon = start.coordinate.longitude;
        if (end) {
            lat = (lat + end.coordinate.latitude) / 2;
            lon = (lon + end.coordinate.longitude) / 2;
        }
    } else if (end) {
        lat = end.coordinate.latitude;
        lon = end.coordinate.longitude;
    }

    if (lat != 0.0f && lon != 0.0f) {
        self.centerCoordinate = CLLocationCoordinate2DMake(lat, lon);
    } else {
        self.centerCoordinate = CLLocationCoordinate2DMake(-255, -255);
    }
    
    [mapView removeAnnotations:[mapView annotations]];
    if (recording.startLocation) {
        OWMapAnnotation *startAnnotation = [[OWMapAnnotation alloc] initWithCoordinate:recording.startLocation.coordinate title:START_STRING subtitle:nil];
        startAnnotation.isStartLocation = YES;
        [mapView addAnnotation:startAnnotation];
    }
    if (recording.endLocation) {
        OWMapAnnotation *endAnnotation = [[OWMapAnnotation alloc] initWithCoordinate:recording.endLocation.coordinate title:END_STRING subtitle:nil];
        [mapView addAnnotation:endAnnotation];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:moviePlayer.view];
    self.scrollView.scrollEnabled = YES;
}

- (void) refreshFields {
    OWManagedRecording *recording = [OWRecordingController recordingForObjectID:self.recordingID];
    if (!recording) {
        return;
    }
    NSString *title = recording.title;
    if (title) {
        self.titleLabel.text = title;
    } else {
        self.titleLabel.text = @"";
    }
    NSString *description = recording.recordingDescription;
    if (description) {
        self.descriptionTextView.text = description;
    } else {
        self.descriptionTextView.text = @"";
    }
    
    self.tallyView.actionsLabel.text = [NSString stringWithFormat:@"%d", [recording.upvotes intValue]];
    self.tallyView.viewsLabel.text = [NSString stringWithFormat:@"%d", [recording.views intValue]];
    self.usernameLabel.text = recording.user.username;
    
    [self.profileImageView setImageWithURL:recording.user.thumbnailURL placeholderImage:[UIImage imageNamed:@"thumbnail_placeholder.png"]];
}







- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
