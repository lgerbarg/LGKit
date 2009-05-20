//
//  LGTSMutableDictionary.h
//  LGTSMutableDictionary
//
//  Created by Louis Gerbarg on 5/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

extern int32_t gObjectAllocs;

#include <libkern/OSAtomic.h>

@interface LGTSMutableDictionary : NSMutableDictionary {
	void * volatile CXXHorrorShow;
	OSSpinLock rootLock;
}
	
@end

@interface LGTSMutableDictionary (Debugging)
- (void) printGraph;
- (void) validate;
@end