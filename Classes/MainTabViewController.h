//
//  MainTabViewController.h
//  linphone
//
//  Created by Tuong Nguyen on 2/18/17.
//
//

#import <MediaPlayer/MediaPlayer.h>

/* These imports are here so that we can import PhoneMainView.h without bothering to import all the rest of the view headers */
#import "StatusBarView.h"
#import "TabBarView.h"

#import "AboutView.h"
#import "AssistantLinkView.h"
#import "AssistantView.h"
#import "CallIncomingView.h"
#import "CallOutgoingView.h"
#import "CallSideMenuView.h"
#import "CallView.h"
#import "ChatConversationCreateView.h"
#import "ChatConversationView.h"
#import "ChatsListView.h"
#import "ContactDetailsView.h"
#import "ContactsListView.h"
#import "CountryListView.h"
#import "DTActionSheet.h"
#import "DialerView.h"
#import "FirstLoginView.h"
#import "HistoryDetailsView.h"
#import "HistoryListView.h"
#import "ImageView.h"
#import "SettingsView.h"
#import "SideMenuView.h"
#import "UIConfirmationDialog.h"
#import "Utils.h"

#define DYNAMIC_CAST(x, cls)                                                                                           \
({                                                                                                                 \
cls *inst_ = (cls *)(x);                                                                                       \
[inst_ isKindOfClass:[cls class]] ? inst_ : nil;                                                               \
})

#define VIEW(x)                                                                                                        \
DYNAMIC_CAST([MainTabViewController.instance.mainViewController getCachedController:x.compositeViewDescription.name], x)

@class MainTabViewController;

@interface RootViewManager : NSObject

@property(nonatomic, strong) MainTabViewController *portraitViewController;
@property(nonatomic, strong) MainTabViewController *rotatingViewController;
@property(nonatomic, strong) NSMutableArray *viewDescriptionStack;

+(RootViewManager*)instance;
+ (void)setupWithPortrait:(MainTabViewController*)portrait;
- (MainTabViewController*)currentView;

@end

@interface MainTabViewController : UITabBarController<IncomingCallViewDelegate> {
    @private NSMutableArray *inhibitedEvents;
}

@property(nonatomic, strong) IBOutlet UIView *statusBarBG;
@property(nonatomic, strong) IBOutlet UICompositeView *mainViewController;

@property(nonatomic, strong) NSString *currentName;
@property(nonatomic, strong) NSString *name;
@property(weak, readonly) UICompositeViewDescription *currentView;
@property LinphoneChatRoom* currentRoom;
@property(readonly, strong) MPVolumeView *volumeView;

- (void)changeCurrentView:(UICompositeViewDescription *)view;
- (UIViewController*)popCurrentView;
- (UIViewController *)popToView:(UICompositeViewDescription *)currentView;
- (UICompositeViewDescription *)firstView;
- (void)hideStatusBar:(BOOL)hide;
- (void)hideTabBar:(BOOL)hide;
- (void)fullScreen:(BOOL)enabled;
- (void)updateStatusBar:(UICompositeViewDescription*)to_view;
- (void)startUp;
- (void)displayIncomingCall:(LinphoneCall*) call;
- (void)setVolumeHidden:(BOOL)hidden;

- (void)addInhibitedEvent:(id)event;
- (BOOL)removeInhibitedEvent:(id)event;

- (void)updateApplicationBadgeNumber;
+ (MainTabViewController*) instance;

@end
