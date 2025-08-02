local AssetService = game:GetService("AssetService")

local ImageUtils = {}

function ImageUtils.CopyImage(image: EditableImage): EditableImage
	return AssetService:CreateEditableImageAsync(Content.fromObject(image))
end

function ImageUtils.SetImageAlpha(image: EditableImage, alpha: number)
	local imageBuffer = image:ReadPixelsBuffer(Vector2.zero, image.Size)
	for i = 3, image.Size.X * image.Size.Y * 4, 4 do
		local a = buffer.readu8(imageBuffer, i)
		buffer.writeu8(imageBuffer, i, math.floor(a * alpha))
	end
	image:WritePixelsBuffer(Vector2.zero, image.Size, imageBuffer)
end

return ImageUtils
