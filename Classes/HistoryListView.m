/* HistoryViewController.m
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
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "HistoryListView.h"
#import "PhoneMainView.h"

@implementation HistoryListView

typedef enum _HistoryView { History_All, History_Missed, History_MAX } HistoryView;

#pragma mark - Lifecycle Functions

- (id)init {
	return [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:StatusBarView.class
																 tabBar:TabBarView.class
															 fullscreen:false
														  landscapeMode:LinphoneManager.runningOnIpad
														   portraitMode:true];
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if ([_tableController isEditing]) {
		[_tableController setEditing:FALSE animated:FALSE];
	}
	[self changeView:History_All];
	[self onEditionChangeClick:nil];

	// Reset missed call
	linphone_core_reset_missed_calls_count([LinphoneManager getLc]);
	// Fake event
	[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCallUpdate object:self];
}

#pragma mark -

- (void)changeView:(HistoryView)view {
	if (view == History_All) {
		_allButton.selected = TRUE;
		[_tableController setMissedFilter:FALSE];
	} else {
		_allButton.selected = FALSE;
	}

	if (view == History_Missed) {
		_missedButton.selected = TRUE;
		[_tableController setMissedFilter:TRUE];
	} else {
		_missedButton.selected = FALSE;
	}
}

#pragma mark - Action Functions

- (IBAction)onAllClick:(id)event {
	[self changeView:History_All];
}

- (IBAction)onMissedClick:(id)event {
	[self changeView:History_Missed];
}

- (IBAction)onDeleteClick:(id)event {
	NSString *msg =
		[NSString stringWithFormat:NSLocalizedString(@"Are you sure that you want to delete %d history?", nil),
								   _tableController.selectedItems.count];
	[UIConfirmationDialog ShowWithMessage:msg
		onCancelClick:^() {
		  [self onEditionChangeClick:nil];
		}
		onConfirmationClick:^() {
		  [_tableController removeSelection];
		  [_tableController loadData];
		  [self onEditionChangeClick:nil];
		}];
}

- (IBAction)onEditionChangeClick:(id)sender {
	_allButton.hidden = _missedButton.hidden = self.tableController.isEditing;
}

@end
