//
//  LGTSDictionaryEnumerator.h
//  DictionaryTester
//
//  Created by Louis Gerbarg on 5/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "LGTSMutableDictionaryNode.h"

@interface LGTSDictionaryEnumerator : NSEnumerator {
	LGTSMutableDictionaryNode *nodes[64];
	NSInteger nodeCount;
	BOOL objectEnumerator;
}

- (id) initWithRootNode:(LGTSMutableDictionaryNode *)node objectEnumerator:(BOOL)objectEnumerator_;

@end
