//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <XCTest/XCTest.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "Segment.h"

@interface SegmentsTestDataSource : NSObject <RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

@end

@interface RTSMediaSegmentsTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) SegmentsTestDataSource *dataSource;
@property (nonatomic) RTSMediaSegmentsController *mediaSegmentsController;

@end

@implementation RTSMediaSegmentsTestCase

#pragma mark - Setup and teardown

- (void)setUp
{
    self.dataSource = [[SegmentsTestDataSource alloc] init];

    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    self.mediaPlayerController.dataSource = self.dataSource;

    self.mediaSegmentsController = [[RTSMediaSegmentsController alloc] init];
    self.mediaSegmentsController.dataSource = self.dataSource;
    self.mediaSegmentsController.playerController = self.mediaPlayerController;
}

- (void)tearDown
{
    self.mediaPlayerController = nil;
    self.mediaSegmentsController = nil;
    self.dataSource = nil;
}

#pragma mark - Tests

// FIXME: Currently, these tests do not check the notification order in a strict way, only that the expected notifications are received. No test also ensures that
//        only the required events are received, not more. This could be improved by inserting waiting times between expectations. For the moment, I only inserted
//        a waiting time when the playback starts

// Expect segment start / end notifications
- (void)testSegmentPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect seek notifications skipping the segment
- (void)testBlockedSegmentPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_blocked_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect segment start / end notifications, as for a visible segment
- (void)testHiddenSegmentPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_hidden_segment" completionHandler:nil];

    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect seek notifications skipping the segment
- (void)testHiddenBlockedSegment
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_hidden_blocked_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect segment start / end notifications
- (void)testSegmentAtStartPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_segment_at_start" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect seek notifications skipping the segment
- (void)testBlockedSegmentAtStartPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_blocked_segment_at_start" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect segment start / end notifications, as for a visible segment
- (void)testHiddenSegmentAtStartPlaythrough
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_hidden_segment_at_start" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect seek notifications skipping the segment
- (void)testHiddenBlockedSegmentAtStart
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_hidden_blocked_segment_at_start" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect segment switch
- (void)testConsecutiveSegments
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_consecutive_segments" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSwitch) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment2");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void)testContiguousBlockedSegments
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_consecutive_blocked_segments" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void)testContiguousBlockedSegmentsAtStart
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_consecutive_blocked_segments_at_start" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void)testSegmentTransitionIntoBlockedSegment
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_segment_transition_into_blocked_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment2");

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment2");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect a start event for the given segment, with YES for the user-driven information flag
- (void)testUserTriggeredSegmentPlay
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];

    id<SRGSegment> firstSegment = [self.mediaSegmentsController.visibleSegments firstObject];
    [self.mediaSegmentsController playSegment:firstSegment];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect a start event for the given segment, with NO for the user-driven information flag (set only when calling -playSegment:)
- (void)testSeekIntoSegment
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertFalse([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];

    [self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(4., NSEC_PER_SEC)];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect a seek
- (void)testUserTriggeredBlockedSegmentPlay
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_blocked_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");

        return YES;
    }];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];

    id<SRGSegment> firstSegment = [self.mediaSegmentsController.visibleSegments firstObject];
    [self.mediaSegmentsController playSegment:firstSegment];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_blocked_segment" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment");

        return YES;
    }];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSeekUponBlockingEnd) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment");
        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey]);

        return YES;
    }];

    [self.mediaPlayerController playAtTime:CMTimeMakeWithSeconds(4., NSEC_PER_SEC)];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

// Expect a switch between the two segments
- (void)testUserTriggeredSegmentPlayAfterUserTriggeredSegmentPlay
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.mediaPlayerController playIdentifier:@"VIDEO-full1"];
    [self.mediaSegmentsController reloadSegmentsForIdentifier:@"SEGMENTS-full_length_with_consecutive_segments" completionHandler:nil];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentStart) {
            return NO;
        }

        XCTAssertNil(notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey]);
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment1");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];

    id<SRGSegment> firstSegment = [self.mediaSegmentsController.visibleSegments firstObject];
    [self.mediaSegmentsController playSegment:firstSegment];
    [self waitForExpectationsWithTimeout:60. handler:nil];

    [self expectationForNotification:SRGMediaPlayerSegmentDidChangeNotification object:self.mediaSegmentsController handler:^BOOL (NSNotification *notification) {
        if ([notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue] != RTSMediaPlaybackSegmentSwitch) {
            return NO;
        }

        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey] name], @"segment1");
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey] name], @"segment2");
        XCTAssertNotNil(notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey]);
        XCTAssertTrue([notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue]);

        return YES;
    }];

    id<SRGSegment> secondSegment = [self.mediaSegmentsController.visibleSegments objectAtIndex:1];
    [self.mediaSegmentsController playSegment:secondSegment];
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

@end

@implementation SegmentsTestDataSource

#pragma mark - RTSMediaPlayerControllerDataSource protocol

- (id)mediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSString *, NSURL *, NSError *))completionHandler
{
    if ([identifier isEqualToString:@"VIDEO-full1"]) {
        completionHandler(identifier, [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"], nil);
    }
    else if ([identifier isEqualToString:@"VIDEO-full2"]) {
        completionHandler(identifier, [NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v"], nil);
    }
    else {
        completionHandler(identifier, nil, [NSError errorWithDomain:@"ch.rts.RTSMediaPlayer-tests" code:1 userInfo:@{ NSLocalizedDescriptionKey: @"Unknown media identifier" }]);
    }

    // No need for a connection handle, completion handlers are called immediately
    return nil;
}

- (void)cancelContentURLRequest:(id)request
{}

#pragma mark - RTSMediaSegmentsDataSource protocol

- (id)segmentsController:(RTSMediaSegmentsController *)controller segmentsForIdentifier:(NSString *)identifier withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
    if ([identifier isEqualToString:@"SEGMENTS-full_length_with_segment"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_blocked_segment"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        segment.blocked = YES;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_hidden_segment"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        segment.visible = NO;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_hidden_blocked_segment"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        segment.blocked = YES;
        segment.visible = NO;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_segment_at_start"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_blocked_segment_at_start"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        segment.blocked = YES;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_hidden_segment_at_start"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        segment.visible = NO;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_hidden_blocked_segment_at_start"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment.logical = YES;
        segment.blocked = YES;
        segment.visible = NO;
        completionHandler(identifier, @[fullLength, segment], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_consecutive_segments"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment1 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment1.logical = YES;

        Segment *segment2 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
        segment2.logical = YES;

        completionHandler(identifier, @[fullLength, segment1, segment2], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_consecutive_blocked_segments"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment1 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment1.logical = YES;
        segment1.blocked = YES;

        Segment *segment2 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
        segment2.logical = YES;
        segment2.blocked = YES;

        completionHandler(identifier, @[fullLength, segment1, segment2], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_consecutive_blocked_segments_at_start"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment1 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment1.logical = YES;
        segment1.blocked = YES;

        Segment *segment2 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(3., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
        segment2.logical = YES;
        segment2.blocked = YES;

        completionHandler(identifier, @[fullLength, segment1, segment2], nil);
    }
    else if ([identifier isEqualToString:@"SEGMENTS-full_length_with_segment_transition_into_blocked_segment"]) {
        Segment *fullLength = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"VIDEO-full1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30. * 60., NSEC_PER_SEC))];
        fullLength.visible = NO;

        Segment *segment1 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
        segment1.logical = YES;

        Segment *segment2 = [[Segment alloc] initWithIdentifier:@"VIDEO-full1" name:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
        segment2.logical = YES;
        segment2.blocked = YES;

        completionHandler(identifier, @[fullLength, segment1, segment2], nil);
    }
    else {
        NSError *error = [NSError errorWithDomain:@"ch.rts.RTSMediaPlayer-tests" code:1 userInfo:@{ NSLocalizedDescriptionKey: @"No segment are available" }];
        completionHandler(identifier, nil, error);
    }

    return nil;
}

- (void)cancelSegmentsRequest:(id)request
{}

@end
