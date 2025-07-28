export type WindowInstance = ScreenGui & {
	Window: Frame & {
		Content: ScrollingFrame,
		Upper: Frame & {
			Separator: Frame?,
			Tabs: (Frame & { TextButton })?,
			Close: TextButton?,
			Title: TextLabel,
		},
		Bottom: (Frame & { TextButton })?,
	},
}

return {}
