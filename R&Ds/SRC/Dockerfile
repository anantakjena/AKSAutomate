FROM mcr.microsoft.com/dotnet/core/sdk:3.0 AS installer-env

COPY . /src/dotnet-function-app
RUN cd /src/dotnet-function-app && \
    mkdir -p /home/site/wwwroot && \
    dotnet publish *.csproj --output /home/site/wwwroot

# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/dotnet:3.0-appservice
FROM mcr.microsoft.com/azure-functions/dotnet:3.0
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
ENV AzureWebJobsStorage=DefaultEndpointsProtocol=https;AccountName=appswkshpstorage;AccountKey=VYXX+w797bvmuq8KGr8bv7NGAzwjiYJaHr2XuPp9qeDc6jlNsvGX/VLIQsVoiF/iS/Xj0wgmJcnfumuaINEGIg==;BlobEndpoint=https://appswkshpstorage.blob.core.windows.net/;QueueEndpoint=https://appswkshpstorage.queue.core.windows.net/;TableEndpoint=https://appswkshpstorage.table.core.windows.net/;FileEndpoint=https://appswkshpstorage.file.core.windows.net/;

COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]