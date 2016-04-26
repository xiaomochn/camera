//
//  ctView.m
//  MSCDemo
//
//  Created by xiaomo on 16/4/25.
//
//

#import "ctView.h"

@implementation ctView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint redBtnPoint = [self convertPoint:point toView:_cameraView];
    if ([_cameraView pointInside:redBtnPoint withEvent:event]) {
        UIView *view = [_cameraView hitTest: redBtnPoint withEvent: event];
        if (view) return view;
//        return _redButton;
    }
    //如果希望严谨一点，可以将上面if语句及里面代码替换成如下代码
    //UIView *view = [_redButton hitTest: redBtnPoint withEvent: event];
    //if (view) return view;
    return [super hitTest:point withEvent:event];
}
@end
