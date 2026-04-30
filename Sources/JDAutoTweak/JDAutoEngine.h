#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, JDAutoState) {
    JDAutoStateIdle     = 0,
    JDAutoStateRunning  = 1,
    JDAutoStatePaused   = 2,
    JDAutoStateStopped  = 3,
};

typedef void(^JDLogBlock)(NSString *msg);
typedef void(^JDStateBlock)(JDAutoState state);

@interface JDAutoEngine : NSObject

@property (nonatomic, copy)   NSString   *phone;
@property (nonatomic, copy)   NSString   *apiURL;
@property (nonatomic, assign) JDAutoState state;
@property (nonatomic, copy)   JDLogBlock  logCallback;
@property (nonatomic, copy)   JDStateBlock stateCallback;

+ (instancetype)shared;

- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

@end
