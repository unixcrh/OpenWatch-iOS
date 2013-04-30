#import "OWMediaObject.h"
#import "OWTag.h"
#import "OWUser.h"
#import "OWUtilities.h"
#import "OWManagedRecording.h"

@interface OWMediaObject ()

// Private interface goes here.

@end


@implementation OWMediaObject

// Custom logic goes here.
- (NSMutableDictionary*) metadataDictionary {
    NSMutableDictionary *newMetadataDictionary = [NSMutableDictionary dictionary];
    if (self.title) {
        [newMetadataDictionary setObject:[self.title copy] forKey:kTitleKey];
    }
    NSSet *tags = self.tags;
    NSMutableArray *tagsArray = [NSMutableArray arrayWithCapacity:tags.count];
    for (OWTag *tag in tags) {
        if ([tag.name isEqualToString:@""]) {
            continue;
        }
        [tagsArray addObject:tag.name];
    }
    [newMetadataDictionary setObject:tagsArray forKey:kTagsKey];
    
    return newMetadataDictionary;
}

- (void) saveMetadata {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}

- (void) loadMetadataFromDictionary:(NSDictionary*)metadataDictionary {
    NSDateFormatter *dateFormatter = [OWUtilities utcDateFormatter];
    NSString *lastEdited = [metadataDictionary objectForKey:kLastEditedKey];
    if (lastEdited) {
        self.modifiedDate = [dateFormatter dateFromString:lastEdited];
    }
    NSString *firstPosted = [metadataDictionary objectForKey:kFirstPostedKey];
    if (firstPosted) {
        self.firstPostedDate = [dateFormatter dateFromString:firstPosted];
    }
    NSNumber *serverID = [metadataDictionary objectForKey:@"id"];
    if (serverID) {
        self.serverID = serverID;
    }    
    NSString *newTitle = [metadataDictionary objectForKey:kTitleKey];
    if (newTitle) {
        self.title = newTitle;
    }
    NSArray *tagsArray = [metadataDictionary objectForKey:kTagsKey];
    if (tagsArray) {
        NSMutableSet *tags = [NSMutableSet set];
        for (NSDictionary *tagDictionary in tagsArray) {
            OWTag *tag = [OWTag tagWithDictionary:tagDictionary];
            [tags addObject:tag];
        }
        self.tags = tags;
    }
    NSDictionary *userDictionary = [metadataDictionary objectForKey:kUserKey];
    if (userDictionary) {
        NSNumber *userID = [userDictionary objectForKey:kIDKey];
        NSString *username = [userDictionary objectForKey:kUsernameKey];
        NSString *thumbnail = [userDictionary objectForKey:@"thumbnail_url"];
        OWUser *user = [OWUser MR_findFirstByAttribute:@"serverID" withValue:userID];
        if (!user) {
            user = [OWUser MR_createEntity];
            user.serverID = userID;
        }
        user.username = username;
        user.thumbnailURLString = thumbnail;
        self.user = user;
    }
    NSNumber *views = [metadataDictionary objectForKey:@"views"];
    if (views) {
        self.views = views;
    }
    NSNumber *clicks = [metadataDictionary objectForKey:@"clicks"];
    if (clicks) {
        self.clicks = clicks;
    }
    NSString *thumbnailURL = [[metadataDictionary objectForKey:@"thumbnail_url"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (thumbnailURL)
        self.thumbnailURLString = thumbnailURL;
}

// stub methods, implemented in subclasses
- (NSURL*) urlForWeb {return nil;}
- (NSString*) type { return nil; }
- (NSURL*) thumbnailURL {
    return [NSURL URLWithString:self.thumbnailURLString];
}

@end
