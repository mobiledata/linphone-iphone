/* SipSettingViewController.h
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <UIKit/UIKit.h>
#import "UICompositeView.h"
#import "TPKeyboardAvoidingScrollView.h"
//#import "PhoneMainView.h"
#import "MainTabViewController.h"

@interface SipSettingViewController : UIViewController <UITextFieldDelegate> {
    
@private
    LinphoneAccountCreator *account_creator;
    LinphoneProxyConfig *new_config;
    size_t number_of_configs_before;
    BOOL mustRestoreView;
    long phone_number_length;
}

// ************* new Mapping ********
@property (weak, nonatomic) IBOutlet UIAssistantTextField *createUsername;
@property (weak, nonatomic) IBOutlet UIAssistantTextField *password;
@property (weak, nonatomic) IBOutlet UIAssistantTextField *domain;
@property (weak, nonatomic) IBOutlet UIAssistantTextField *displayName;
@property (weak, nonatomic) IBOutlet UISegmentedControl *transportSegment;


// ************* end new Mapping ********

@property(nonatomic) UICompositeViewDescription *outgoingView;

@property(nonatomic, strong) IBOutlet TPKeyboardAvoidingScrollView *contentView;
@property(nonatomic, strong) IBOutlet UIView *waitView;
@property(nonatomic, strong) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *infoLoginButton;

@property(nonatomic, strong) IBOutlet UIView *loginView;

@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *createAccountNextButtonPositionConstraint;

+ (NSString *)errorForStatus:(LinphoneAccountCreatorStatus)status;
+ (NSString *)StringForXMLRPCError:(const char *)err;

- (void)reset;
- (void)fillDefaultValues;

- (IBAction)onLoginClick:(id)sender;
@end
