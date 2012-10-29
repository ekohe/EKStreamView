`EKStreamView` renders a number of columns containing multiple cells by reusing the cell views whenever possible, similar to `UITableView`. It's fast even you have hundreds of cells since only a small number of cells are actually created.

![EKStreamView](https://github.com/ekohe/EKStreamView/raw/master/screenshot.png "Screenshot")

## Usage ##

Copy `EKStreamView.h` and `EKStreamView.m` to your project. This class is ARC-enabled. You must build it with ARC.

Implement the required methods in `EKStreamViewDelegate` protocol, and implement the optional ones optionally. This class acts very similar as `UITableView`. However, in a `UITableView`, your cell should subclass `UITableViewCell`, while in `EKStreamView`, your cell is only required to conform to the protocol `EKResusableCell` to provide a reuse ID.