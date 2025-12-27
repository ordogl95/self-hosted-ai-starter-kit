// Loop over input items and extract image names from md_content
const outputItems = [];

for (const item of $input.all()) {
  const imageNames = [];

  if (item.json.document && item.json.document.md_content) {
    const mdContent = item.json.document.md_content;
    
    // Regex to match markdown image syntax: ![Alt text](filename.png)
    const imageRegex = /!\[.*?\]\((.*?)\)/g;
    let match;

    // Find all image matches and extract the filenames
    while ((match = imageRegex.exec(mdContent)) !== null) {
      imageNames.push(match[1]);
    }
  }

  // Create a separate output item for each image name
  for (const imageName of imageNames) {
    const newItem = JSON.parse(JSON.stringify(item));
    newItem.json.imageName = imageName;
    outputItems.push(newItem);
  }
}

return outputItems;
