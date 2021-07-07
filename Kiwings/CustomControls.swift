//
//  CustomControls.swift
//  Kiwings
//
//  Created by Maheep Kumar Kathuria on 21/06/21.
//

import SwiftUI

struct MKContentTable: NSViewRepresentable {
    @Binding var data: [KiwixLibraryFile]
    @Binding var selection: [Int]
    
    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var parent: MKContentTable
        
        init(_ parent: MKContentTable) {
            self.parent = parent
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            return parent.data.count
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
            let tableView = notification.object as! NSTableView
            parent.selection = tableView.selectedRowIndexes.map({ $0 })
        }
        
        @objc func setEnableValue(_ sender: NSButton) {
            self.parent.data[sender.tag].isEnabled = (sender.state == .on) ? true : false
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            if tableColumn?.identifier.rawValue == "libFiles" {
//                let textField = NSHostingView(rootView: Text("MK1-Nib"))
                let x = NSTableCellView()
                let textField = NSTextField(labelWithAttributedString: NSAttributedString(string: URL(fileURLWithPath: self.parent.data[row].path).absoluteURL.lastPathComponent, attributes: [.font : NSFont.systemFont(ofSize: 11, weight: .medium)]))
                x.addSubview(textField)
                textField.translatesAutoresizingMaskIntoConstraints = false
                x.addConstraint(NSLayoutConstraint(item: textField, attribute: .centerY, relatedBy: .equal, toItem: x, attribute: .centerY, multiplier: 1, constant: 0))
                return x
            } else if tableColumn?.identifier.rawValue == "isEnabled" {
                let checkboxField = NSButton()
                checkboxField.setButtonType(.switch)
                checkboxField.state = self.parent.data[row].isEnabled ? .on : .off
                checkboxField.title = ""
                checkboxField.target = self
                checkboxField.action = #selector(setEnableValue(_:))
                checkboxField.tag = row
                return checkboxField
            } else {
                return nil
            }
        }
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let tableView = NSTableView()
        tableView.allowsMultipleSelection = true
        tableView.headerView = NSTableHeaderView()
        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "libFiles"))
        col1.title = "Library Files"
        tableView.addTableColumn(col1)
        
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "isEnabled"))
        col2.title = "Enabled"
        tableView.addTableColumn(col2)
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.rowHeight = 18
        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.borderType = .lineBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let tableView = (nsView.documentView as! NSTableView)
        context.coordinator.parent = self
        // actually, model should tell us if reload is needed or not
        tableView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
}

struct MKTableSegmentControl: NSViewRepresentable {
    
    var onChange: ((_ control: NSSegmentedControl) -> Void)?
    
    func makeCoordinator() -> MKTableSegmentControl.Coordinator {
        Coordinator(parent: self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MKTableSegmentControl>) -> NSSegmentedControl {
        let control = NSSegmentedControl(
            images: [
                NSImage(named: NSImage.addTemplateName)!,
                NSImage(named: NSImage.removeTemplateName)!,
                NSImage()
            ],
            trackingMode: .momentary,
            target: context.coordinator,
            action: #selector(Coordinator.onChange(_:))
        )
        control.setWidth(32, forSegment: 0)
        control.setWidth(32, forSegment: 1)
        control.setEnabled(false, forSegment: 2)
        control.segmentStyle = .smallSquare
        return control
    }
    
    func updateNSView(_ nsView: NSSegmentedControl, context: NSViewRepresentableContext<MKTableSegmentControl>) {
    }
    
    class Coordinator {
        let parent: MKTableSegmentControl
        
        init(parent: MKTableSegmentControl) {
            self.parent = parent
        }
        
        @objc func onChange(_ control: NSSegmentedControl) {
            if let onChangeFunc = self.parent.onChange {
                onChangeFunc(control)
            }
        }
    }
}

struct CheckmarkToggleStyle: ToggleStyle {
    var scaleFactor: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Rectangle()
                .foregroundColor(configuration.isOn ? .green : .gray)
                .frame(width: 51*scaleFactor, height: 31*scaleFactor, alignment: .center)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .padding(.all, 3*scaleFactor)
                        .overlay(
                            Image(systemName: configuration.isOn ? "checkmark" : "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .font(Font.title.weight(.black))
                                .frame(width: 8*scaleFactor, height: 8*scaleFactor, alignment: .center)
                                .foregroundColor(configuration.isOn ? .green : .gray)
                        )
                        .offset(x: configuration.isOn ? 11*scaleFactor : -11*scaleFactor, y: 0)
                        .animation(Animation.linear(duration: 0.1))
                        
                ).cornerRadius(20*scaleFactor)
                .padding(EdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 0))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct StepperField: View {
    var placeholderText: String
    var value: Binding<Int>
    var minValue: Int?
    var maxValue: Int?
    var body: some View {
        ZStack {
            let binding = Binding<Int>(
                get: { self.value.wrappedValue },
                set: { self.value.wrappedValue = $0 }
            )
            TextField(placeholderText, value: binding, formatter: NumberFormatter()).textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
            HStack(alignment: .center) {
                Button(action: {
                    self.value.wrappedValue -= 1
                    if let minimumVal = minValue {
                        self.value.wrappedValue = max(minimumVal, self.value.wrappedValue)
                    }
                }, label: {
                    Text("−").bold()
                }).buttonStyle(PlainButtonStyle()).frame(width: 16, height: 16, alignment: .center)
                Spacer()
                Button(action: {
                    self.value.wrappedValue += 1
                    if let maxVal = maxValue {
                        self.value.wrappedValue = min(maxVal, self.value.wrappedValue)
                    }
                }, label: {
                    Text("+").bold()
                }).buttonStyle(PlainButtonStyle()).frame(width: 16, height: 16, alignment: .center)
            }
        }
    }
}
