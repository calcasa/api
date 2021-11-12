#!/bin/bash

spec_url=https://api.calcasa.nl/api-docs/v0/openapi.yaml
# Spec file to use
spec_file=openapi.yaml
# Output directory
output_dir=generated

template_dir=templates

submodule_dir=libraries
submodule_prefix=api-


# Where all the openapi-generator config files are located.
config_dir=configs
# Prefix to strip
config_prefix=config-

wget -O openapi.yaml $spec_url

echo "Removing $output_dir..."
rm -rf $output_dir
echo "Making sure $output_dir exists..."


mkdir -p $output_dir

# Docker volume mappings
volumes="-v $(readlink -e $(dirname $spec_file))/$(basename $spec_file):/spec/$(basename $spec_file) -v $(readlink -e $output_dir):/out -v $(readlink -e $config_dir):/config -v $(readlink -e $template_dir):/templates"

echo "Validating $(basename $spec_file) spec file..."
docker run --rm -t \
  ${volumes} openapitools/openapi-generator-cli:latest validate \
  -i /spec/$(basename $spec_file) 

for i in `ls ${config_dir}/${config_prefix}*.yaml`
do
i=$(basename $i)
i=${i#"$config_prefix"}
i=${i%".yaml"}

generator=$i

if [ "$i" == "csharp" ]; then
    generator=$i-netcore
fi

mkdir -p $template_dir/$i

echo "Generating $i client..."
docker run --rm -t \
  ${volumes} openapitools/openapi-generator-cli:latest generate \
  --ignore-file-override /config/.openapi-generator-ignore \
  -i /spec/$(basename $spec_file) \
  -g $generator \
  -c /config/config-$i.yaml \
  -o /out/$i \
  -t /templates/$i

rm -rf $output_dir/$i/git_push.sh $output_dir/$i/appveyor.yml $output_dir/$i/docs $output_dir/$i/appveyor.yml

cp LICENSE $output_dir/$i/LICENSE

if [ "$i" == "php" ]; then
    echo "Postprocessing generated PHP files."
    php postprocess/php/php-postprocess.php $output_dir/$i/lib/Model
fi

if [ -d "$submodule_dir/$submodule_prefix$i/" ]; then
  # Take action if $DIR exists. #
  echo "Copying generated files to git repo..."
  cp -rf $output_dir/$i/* "$submodule_dir/$submodule_prefix$i/"
fi

done
